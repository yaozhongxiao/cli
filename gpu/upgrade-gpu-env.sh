#!/usr/bin/env bash
#
# upgrade-gpu-env.sh — Upgrade system to meet cuTile requirements
# Requirements: NVIDIA Driver >= R580, CUDA >= 13.1, cuDNN >= 9.x for CUDA 13, Python >= 3.10, cuda-tile
#
set -euo pipefail

# helpers
log_info() { echo "[INFO] $*"; }
log_ok()   { echo "[✓] $*"; }
log_fail() { echo "[✗] $*" >&2; }

# apt-get wrapper: quiet by default, full output with --verbose
apt_get() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        apt-get "$@"
    else
        apt-get -qq "$@"
    fi
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_fail "This script must be run as root (use sudo)."
        exit 1
    fi
}

# Run a command as the real user using bash (no login shell, preserves PATH)
run_as_user() {
    su -s /bin/bash "${REAL_USER}" -c "$*"
}

# Resolve the real user who invoked sudo (falls back to root if run directly as root)
REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME=$(getent passwd "${REAL_USER}" | cut -d: -f6)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pyenv_root="${REAL_HOME}/.pyenv"
bashrc="${REAL_HOME}/.bashrc"

# ── Step 1: Python (pyenv, per-user) ──────────────────────────────────────────
# PYTHON_VERSION is set by configure_versions() from CUDA_VERSION_MAP

upgrade_python() {
    log_info "Step 1/6: Installing Python ${PYTHON_VERSION} via pyenv for current user..."

    # Install pyenv build dependencies
    log_info "Installing pyenv build dependencies..."
    apt_get install -y \
        make build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev

    # Install pyenv if not already present
    if [[ ! -d "${pyenv_root}" ]]; then
        log_info "Installing pyenv for user ${REAL_USER}..."
        run_as_user "curl https://pyenv.run | bash"
    else
        log_ok "pyenv already present at ${pyenv_root}."
    fi

    # Install Python 3.10.0 if not already installed
    if run_as_user "PYENV_ROOT='${pyenv_root}' '${pyenv_root}/bin/pyenv' versions --bare 2>/dev/null" \
            | grep -qx "${PYTHON_VERSION}"; then
        log_ok "Python ${PYTHON_VERSION} already installed via pyenv."
    else
        log_info "Compiling Python ${PYTHON_VERSION} — this takes a few minutes..."
        run_as_user "PYENV_ROOT='${pyenv_root}' '${pyenv_root}/bin/pyenv' install '${PYTHON_VERSION}'"
    fi

    # Set as global default for the user
    run_as_user "PYENV_ROOT='${pyenv_root}' '${pyenv_root}/bin/pyenv' global '${PYTHON_VERSION}'"

    # Add pyenv init to .bashrc if not already configured
    if ! grep -q "pyenv init" "${bashrc}" 2>/dev/null; then
        {
            echo ""
            echo "# pyenv"
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'eval "$(pyenv init -)"'
        } >> "${bashrc}"
        log_info "Added pyenv init to ${bashrc}."
    fi

    local py_ver
    py_ver=$(run_as_user "PYENV_ROOT='${pyenv_root}' PATH='${pyenv_root}/bin:${pyenv_root}/shims:/usr/bin:/bin:\$PATH' python --version 2>/dev/null" \
        || echo "unknown")
    log_ok "${py_ver} installed and set as default for ${REAL_USER}. Run: source ~/.bashrc"
}

# https://docs.nvidia.com/cuda/cuda-toolkit-release-notes
#  ┌─────────────────────┬─────────────────┬──────────┬──────────┐
#  │    CUDA Toolkit     │   最低驱动版本  │  cuDNN   │  Python  │
#  ├─────────────────────┼─────────────────┼──────────┼──────────┤
#  │ 13.3 GA / Update 1  │ >= 610.43.02    │ 9.24.0   │ >= 3.10  │
#  │ 13.1 GA             │ >= 590.44.01    │ 9.19.0   │ >= 3.10  │
#  │ 13.0 GA             │ >= 580.65.06    │ 9.x      │ >= 3.10  │
#  │ 12.9 GA             │ >= 575.51.03    │ 9.x      │ >= 3.10  │
#  │ 12.8 GA             │ >= 570.26.06    │ 8.9.x    │ >= 3.10  │
#  └─────────────────────┴─────────────────┴──────────┴──────────┘

# https://docs.nvidia.com/deeplearning/cudnn/backend/latest/reference/support-matrix.html
# ── Version lookup tables ──────────────────────────────────────────────────────
# Key: CUDA full version (x.y.z)  Value: "DRIVER_VERSION CUDNN_VERSION PYTHON_VERSION"
declare -A CUDA_VERSION_MAP=(
    ["13.1.0"]="590.44.01 9.19.0 3.10.0"
    ["13.3.1"]="610.43.02 9.24.0 3.10.0"
)

# ──  NVIDIA Driver ──────────────────────────────────────────────────────

# Set by configure_versions()
NVIDIA_DRIVER_VERSION=""
NVIDIA_RUN_INSTALLER=""
NVIDIA_RUN_INSTALLER_PATH=""
NVIDIA_DRIVER_URL=""

# ── CUDA Toolkit ──────────────────────────────────────────────────────
# Set by configure_versions()
CUDA_VERSION=""
CUDA_MAJOR=""
CUDA_VERSION_SHORT=""
CUDA_INSTALL_DIR=""
CUDA_PROFILE_SH=""
CUDA_BASHRC_MARKER=""
CUDA_BASHRC_BEGIN=""
CUDA_BASHRC_END=""
CUDA_INSTALLER=""
CUDA_URL=""

configure_versions() {
    local cuda_ver="$1"
    local entry="${CUDA_VERSION_MAP[${cuda_ver}]:-}"
    if [[ -z "${entry}" ]]; then
        log_fail "Unsupported --cuda-version '${cuda_ver}'. Valid options: ${!CUDA_VERSION_MAP[*]}"
        exit 1
    fi
    CUDA_VERSION="${cuda_ver}"
    read -ra _fields <<< "${entry}"
    NVIDIA_DRIVER_VERSION="${_fields[0]}"
    CUDNN_VERSION="${_fields[1]}"
    PYTHON_VERSION="${_fields[2]}"

    #──────────────────  cuda toolkit config ──────────────────────
    CUDA_MAJOR="${CUDA_VERSION%%.*}"
    CUDA_VERSION_SHORT="${CUDA_VERSION%.*}"
    CUDA_INSTALL_DIR="/usr/local/cuda-${CUDA_VERSION_SHORT}"
    CUDA_PROFILE_SH="/etc/profile.d/cuda-${CUDA_VERSION_SHORT}.sh"
    CUDA_BASHRC_MARKER="cuda-${CUDA_VERSION_SHORT}"
    CUDA_BASHRC_BEGIN="# >>> CUDA_TOOLKIT_ENV >>>"
    CUDA_BASHRC_END="# <<< CUDA_TOOLKIT_ENV <<<"
    CUDA_INSTALLER="cuda_${CUDA_VERSION}_${NVIDIA_DRIVER_VERSION}_linux.run"
    CUDA_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_INSTALLER}"
    
    #──────────────────  nvidia driver config ──────────────────────
    NVIDIA_RUN_INSTALLER="NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
    NVIDIA_RUN_INSTALLER_PATH="${script_dir}/${NVIDIA_RUN_INSTALLER}"
    NVIDIA_DRIVER_URL="https://download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER_VERSION}/${NVIDIA_RUN_INSTALLER}"

    #──────────────────  cudnn config ──────────────────────
    CUDNN_DEB="cudnn-local-repo-ubuntu2204-${CUDNN_VERSION}_1.0-1_amd64.deb"
    CUDNN_URL="https://developer.download.nvidia.com/compute/cudnn/${CUDNN_VERSION}/local_installers/${CUDNN_DEB}"
    CUDNN_CUDA_MAJOR="${CUDA_MAJOR}"

    #──────────────────  cutlass config ──────────────────────
    CUTLASS_INSTALL_DIR="${CUDA_INSTALL_DIR}"

    log_info "Target: CUDA ${CUDA_VERSION}  |  Driver ${NVIDIA_DRIVER_VERSION}  |  Install dir: ${CUDA_INSTALL_DIR}"
    echo "  ┌─ Installation Plan ──────────────────────────────────────"
    echo "  │  CUDA version   : ${CUDA_VERSION}"
    echo "  │  Driver version : ${NVIDIA_DRIVER_VERSION}"
    echo "  │  cuDNN version  : ${CUDNN_VERSION}"
    echo "  │  Install dir    : ${CUDA_INSTALL_DIR}"
    echo "  └──────────────────────────────────────────────────────────"
    echo ""
    if [[ "${FORCE}" != "1" ]]; then
        read -r -p "  Proceed with installation? [y/N] " confirm
        case "${confirm}" in
            [yY][eE][sS]|[yY]) ;;
            *)
                echo "Aborted."
                exit 0
                ;;
        esac
    fi
    echo ""
}

# ── Step 2: NVIDIA Driver ──────────────────────────────────────────────────────

upgrade_driver() {
    log_info "Step 2/6: Installing NVIDIA driver ${NVIDIA_DRIVER_VERSION} from local .run installer..."

    if [[ ! -f "${NVIDIA_RUN_INSTALLER_PATH}" ]]; then
        log_info "Installer not found: ${NVIDIA_RUN_INSTALLER_PATH}"
        echo ""
        echo "  ┌─ NVIDIA Driver ${NVIDIA_DRIVER_VERSION} ────────────────────────────────────────"
        echo "  │  To download manually instead, Ctrl-C now and run:"
        echo "  │"
        echo "  │    wget -c -O '${NVIDIA_RUN_INSTALLER_PATH}' \\"
        echo "  │      '${NVIDIA_DRIVER_URL}'"
        echo "  │"
        echo "  │  Then re-run this script."
        echo "  └──────────────────────────────────────────────────────────────────"
        echo ""
        local i
        for i in 5 4 3 2 1; do
            printf "\r  Download starts in %ds  (Ctrl-C to abort) ..." "${i}"
            sleep 1
        done
        printf "\r  %-60s\n" ""
        echo ""

        local attempt=1 max_attempts=5
        while [[ ${attempt} -le ${max_attempts} ]]; do
            log_info "Downloading NVIDIA driver ${NVIDIA_DRIVER_VERSION} (attempt ${attempt}/${max_attempts})..."
            if wget -c \
                    --progress=bar:force:noscroll \
                    --timeout=60 \
                    --tries=1 \
                    --retry-connrefused \
                    -O "${NVIDIA_RUN_INSTALLER_PATH}" "${NVIDIA_DRIVER_URL}" 2>&1; then
                break
            fi
            log_info "Download interrupted (attempt ${attempt}/${max_attempts}). Retrying in 3s..."
            sleep 3
            attempt=$(( attempt + 1 ))
        done

        if [[ ! -f "${NVIDIA_RUN_INSTALLER_PATH}" ]]; then
            log_fail "Download failed after ${max_attempts} attempts."
            log_fail "Download manually:  wget -c -O '${NVIDIA_RUN_INSTALLER_PATH}' '${NVIDIA_DRIVER_URL}'"
            exit 1
        fi
        log_ok "NVIDIA driver installer downloaded: ${NVIDIA_RUN_INSTALLER_PATH}"
        echo ""
    fi

    # Stop display manager to release nvidia-drm module
    local dm=""
    for svc in gdm3 gdm lightdm sddm; do
        if systemctl is-active --quiet "${svc}" 2>/dev/null; then
            dm="${svc}"
            break
        fi
    done
    if [[ -n "${dm}" ]]; then
        log_info "Stopping display manager (${dm}) to release nvidia modules..."
        systemctl stop "${dm}"
    fi

    # Unload nvidia kernel modules in dependency order
    log_info "Unloading nvidia kernel modules..."
    for mod in nvidia_uvm nvidia_modeset nvidia_drm nvidia; do
        if lsmod | grep -q "^${mod} "; then
            modprobe -r "${mod}" 2>/dev/null || rmmod --force "${mod}" 2>/dev/null || true
        fi
    done

    # Verify nvidia-drm is unloaded; abort if still busy
    if lsmod | grep -q "^nvidia_drm "; then
        log_fail "nvidia-drm is still loaded. Kill all processes using it and retry:"
        log_fail "  sudo lsof /dev/nvidia* | awk 'NR>1{print \$2}' | sort -u | xargs kill -9"
        exit 1
    fi

    # Remove existing apt-managed nvidia packages (.run installer conflicts with deb installs)
    log_info "Removing apt-managed nvidia driver packages to avoid conflicts..."
    apt_get remove --purge -y \
        'nvidia-driver-*' \
        'libnvidia-*' \
        'nvidia-dkms-*' \
        'nvidia-kernel-*' \
        'nvidia-compute-utils-*' \
        'nvidia-firmware-*' \
        'nvidia-modprobe' \
        'nvidia-settings' \
        'nvidia-utils-*' \
        'xserver-xorg-video-nvidia-*' \
        2>/dev/null || true
    apt_get autoremove -y 2>/dev/null || true

    # Install build deps needed by .run installer (libglvnd EGL config path)
    apt_get install -y pkg-config libglvnd-dev

    chmod +x "${NVIDIA_RUN_INSTALLER_PATH}"
    sh "${NVIDIA_RUN_INSTALLER_PATH}" \
        --silent \
        --no-questions \
        --ui=none \
        --disable-nouveau \
        --kernel-source-path=/usr/src/linux-headers-$(uname -r)

    # Restart display manager if we stopped it
    if [[ -n "${dm}" ]]; then
        log_info "Restarting display manager (${dm})..."
        systemctl start "${dm}" || true
    fi

    log_ok "NVIDIA driver ${NVIDIA_DRIVER_VERSION} installed. A reboot is required for the driver to take effect."
    echo "    >> Please reboot after this script completes, then re-run to verify."
}

# ── Step 3: CUDA Toolkit ──────────────────────────────────────────────────────

update_cuda_env_config() {
    # Keep shell/profile exports in sync whether CUDA was newly installed or reused.
    cat > "${CUDA_PROFILE_SH}" << ENVEOF
export CUDA_VERSION="${CUDA_VERSION}"
export CUDA_INSTALL_DIR="${CUDA_INSTALL_DIR}"
export CUDA_HOME="\${CUDA_INSTALL_DIR}"
export CUDA_PATH="\${CUDA_INSTALL_DIR}"
export PATH="\${CUDA_INSTALL_DIR}/bin:\$PATH"
export LD_LIBRARY_PATH="\${CUDA_INSTALL_DIR}/lib64:\${LD_LIBRARY_PATH:-}"
ENVEOF
    chmod 644 "${CUDA_PROFILE_SH}"

    # Force-overwrite managed CUDA block in ~/.bashrc
    touch "${bashrc}"
    sed -i "/^${CUDA_BASHRC_BEGIN//\//\\\/}$/,/^${CUDA_BASHRC_END//\//\\\/}$/d" "${bashrc}" || true
    {
        echo ""
        echo "${CUDA_BASHRC_BEGIN}"
        echo "# CUDA ${CUDA_VERSION}"
        echo "export CUDA_VERSION=${CUDA_VERSION}"
        echo "export CUDA_INSTALL_DIR=${CUDA_INSTALL_DIR}"
        echo "export CUDA_HOME=\${CUDA_INSTALL_DIR}"
        echo "export CUDA_PATH=\${CUDA_INSTALL_DIR}"
        echo "export PATH=\${CUDA_INSTALL_DIR}/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=\${CUDA_INSTALL_DIR}/lib64:\${LD_LIBRARY_PATH:-}"
        echo "${CUDA_BASHRC_END}"
    } >> "${bashrc}"

    log_ok "Environment configured. Run: source ~/.bashrc"
}

upgrade_cuda() {
    log_info "Step 3/6: Installing CUDA Toolkit ${CUDA_VERSION}..."
    log_info "  version:     ${CUDA_VERSION}"
    log_info "  install dir: ${CUDA_INSTALL_DIR}"
    log_info "  package:     ${script_dir}/${CUDA_INSTALLER}"

    if [[ -d "${CUDA_INSTALL_DIR}" ]]; then
        log_ok "CUDA ${CUDA_VERSION} already installed at ${CUDA_INSTALL_DIR}, skipping."
        update_cuda_env_config
        return 0
    fi
    local local_installer="${script_dir}/${CUDA_INSTALLER}"

    # ── Download with resume support ─────────────────────────────────────────
    # Get expected file size from server (Content-Length)
    local expected_bytes
    expected_bytes=$(wget -q --spider --server-response "${CUDA_URL}" 2>&1 \
        | grep -i "Content-Length" | tail -1 | awk '{print $2}' | tr -d '\r' || echo "0")

    # Check if file is already fully downloaded
    local need_download=1
    if [[ -f "${local_installer}" ]]; then
        local actual_bytes
        actual_bytes=$(stat -c%s "${local_installer}" 2>/dev/null || echo "0")
        if [[ "${expected_bytes}" -gt 0 && "${actual_bytes}" -ge "${expected_bytes}" ]]; then
            log_ok "CUDA ${CUDA_VERSION} installer already fully downloaded ($(( actual_bytes / 1024 / 1024 ))MB)."
            need_download=0
        else
            log_warn "Partial download detected ($(( actual_bytes / 1024 / 1024 ))MB / $(( expected_bytes / 1024 / 1024 ))MB). Resuming..."
        fi
    fi

    if [[ ${need_download} -eq 1 ]]; then
        echo ""
        echo "  ┌─ CUDA ${CUDA_VERSION} installer (~$(( expected_bytes / 1024 / 1024 / 1024 + 1 ))GB) ─────────────────────────────────"
        echo "  │  To download manually instead, Ctrl-C now and run:"
        echo "  │"
        echo "  │    wget -c -O '${local_installer}' \\"
        echo "  │      '${CUDA_URL}'"
        echo "  │"
        echo "  │  Then re-run this script."
        echo "  └──────────────────────────────────────────────────────────────────"
        echo ""
        local i
        for i in 5 4 3 2 1; do
            printf "\r  Download starts in %ds  (Ctrl-C to abort) ..." "${i}"
            sleep 1
        done
        printf "\r  %-60s\n" ""
        echo ""

        local attempt=1
        local max_attempts=5
        while [[ ${attempt} -le ${max_attempts} ]]; do
            log_info "Downloading CUDA ${CUDA_VERSION} installer (attempt ${attempt}/${max_attempts})..."
            # -c: resume; --retry-connrefused: retry on connection refused
            # progress bar goes to stderr, 2>&1 brings it to stdout for tee-safe display
            if wget -c \
                    --progress=bar:force:noscroll \
                    --timeout=60 \
                    --tries=1 \
                    --retry-connrefused \
                    -O "${local_installer}" "${CUDA_URL}" 2>&1; then
                break
            fi
            log_warn "Download interrupted (attempt ${attempt}/${max_attempts}). Retrying in 3s..."
            sleep 3
            attempt=$(( attempt + 1 ))
        done

        # Final size check after all attempts
        local final_bytes
        final_bytes=$(stat -c%s "${local_installer}" 2>/dev/null || echo "0")
        if [[ "${expected_bytes}" -gt 0 && "${final_bytes}" -lt "${expected_bytes}" ]]; then
            log_fail "Download incomplete after ${max_attempts} attempts (${final_bytes}/${expected_bytes} bytes)."
            log_fail "Partial file kept at: ${local_installer}"
            log_fail "Re-run this script to resume, or download manually:"
            log_fail "  wget -c -O '${local_installer}' '${CUDA_URL}'"
            exit 1
        fi
        log_ok "Download complete: ${local_installer} ($(( final_bytes / 1024 / 1024 ))MB)"
        echo ""
    fi

    # ── Run installer, show spinner + elapsed time + live log tail ────────────
    chmod +x "${local_installer}"
    local log_file
    log_file="$(mktemp /tmp/cuda-install-XXXXXX.log)"

    log_info "Running CUDA ${CUDA_VERSION} installer (toolkit only)" \
             "—> ${CUDA_INSTALL_DIR}, please wait..."
    sh "${local_installer}" --silent --toolkit --override \
        --installpath="${CUDA_INSTALL_DIR}" \
        > "${log_file}" 2>&1 &
    local installer_pid=$!

    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local idx=0 elapsed=0 last_line=""
    while kill -0 "${installer_pid}" 2>/dev/null; do
        last_line=$(tail -1 "${log_file}" 2>/dev/null | tr -d '\r' || true)
        printf "\r  %s  [%3ds]  %-55.55s" \
            "${spin[$((idx % 10))]}" "${elapsed}" "${last_line}"
        sleep 1
        idx=$(( idx + 1 ))
        elapsed=$(( elapsed + 1 ))
    done
    printf "\r  %-72s\n" ""   # clear spinner line

    wait "${installer_pid}"
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_fail "CUDA installer failed (exit ${exit_code}). Full log: ${log_file}"
        echo "--- last 20 lines ---" >&2
        tail -20 "${log_file}" >&2
        exit 1
    fi
    rm -f "${log_file}"
    log_ok "CUDA ${CUDA_VERSION} installed (${elapsed}s)."

    update_cuda_env_config
}

# ── Step 4: cuDNN ─────────────────────────────────────────────────────────────
# Set by configure_versions() from CUDA_MAJOR
CUDNN_CUDA_MAJOR=""
CUDNN_VERSION=""
CUDNN_DEB=""
CUDNN_URL=""

upgrade_cudnn() {
    log_info "Step 4/6: Installing cuDNN ${CUDNN_VERSION} for CUDA ${CUDNN_CUDA_MAJOR}..."

    # Check if cuDNN for CUDA 13 is already installed
    if dpkg -l "libcudnn9-cuda-${CUDNN_CUDA_MAJOR}" 2>/dev/null | grep -q "^ii"; then
        local installed_ver
        installed_ver=$(dpkg -l "libcudnn9-cuda-${CUDNN_CUDA_MAJOR}" 2>/dev/null \
            | awk '/^ii/{print $3}' | cut -d- -f1)
        log_ok "cuDNN ${installed_ver} for CUDA ${CUDNN_CUDA_MAJOR} already installed, skipping."
        return 0
    fi

    local local_deb="${script_dir}/${CUDNN_DEB}"

    # ── Download local repo deb if not present ────────────────────────────────
    if [[ ! -f "${local_deb}" ]]; then
        log_info "Downloading cuDNN ${CUDNN_VERSION} local repo package..."
        echo ""
        echo "  NOTE: If the download fails (NVIDIA requires a developer account for some"
        echo "  versions), download manually from https://developer.nvidia.com/cudnn and"
        echo "  place the file at: ${local_deb}"
        echo "  Then re-run this script."
        echo ""

        local attempt=1 max_attempts=3
        while [[ ${attempt} -le ${max_attempts} ]]; do
            if wget -c --progress=bar:force:noscroll --timeout=60 --tries=1 \
                    -O "${local_deb}" "${CUDNN_URL}" 2>&1; then
                break
            fi
            log_info "Download attempt ${attempt}/${max_attempts} failed. Retrying in 3s..."
            sleep 3
            attempt=$(( attempt + 1 ))
        done

        if [[ ! -s "${local_deb}" ]]; then
            log_fail "cuDNN download failed after ${max_attempts} attempts."
            log_fail "Download manually: ${CUDNN_URL}"
            log_fail "Place at: ${local_deb}  and re-run."
            exit 1
        fi
    else
        log_ok "cuDNN local repo deb already present: ${local_deb}"
    fi

    # ── Install local repo deb → add apt source → install packages ───────────
    dpkg -i "${local_deb}"

    # Copy GPG keyring from the exact repo directory this deb installed into
    local repo_name
    repo_name="cudnn-local-repo-${CUDNN_DEB##cudnn-local-repo-}"   # strip prefix
    repo_name="${repo_name%%_*}"                                     # strip _1.0-1_amd64.deb suffix
    local keyring
    keyring=$(find "/var/${repo_name}" -name "cudnn-local-*-keyring.gpg" 2>/dev/null | head -1)
    if [[ -n "${keyring}" ]]; then
        cp "${keyring}" /usr/share/keyrings/
        log_ok "Installed GPG keyring: $(basename "${keyring}")"
    else
        log_fail "GPG keyring not found under /var/${repo_name} — apt-get update will fail."
        exit 1
    fi

    apt_get update
    # Install runtime + dev + static for CUDA 13
    apt_get install -y \
        "libcudnn9-cuda-${CUDNN_CUDA_MAJOR}" \
        "libcudnn9-dev-cuda-${CUDNN_CUDA_MAJOR}" \
        "libcudnn9-static-cuda-${CUDNN_CUDA_MAJOR}"

    log_ok "cuDNN ${CUDNN_VERSION} for CUDA ${CUDNN_CUDA_MAJOR} installed."
}


# ── Step 5: CUTLASS C++ headers (header-only, cmake install) ──────────────────
# Install into devtools/gpu/cutlass/ (user-writable).
# Add to CMAKE_PREFIX_PATH so find_package(NvidiaCutlass) resolves it.
CUTLASS_SRC_DIR="${REAL_HOME}/workspace/cuda-dev/cutlass"
# CUTLASS_INSTALL_DIR is set by configure_versions()

install_cutlass() {
    log_info "Step 5/6: Installing CUTLASS C++ headers (CUDA ${CUDA_VERSION_SHORT} matched)..."

    if [[ ! -d "${CUTLASS_SRC_DIR}" ]]; then
        log_info "CUTLASS source not found at ${CUTLASS_SRC_DIR} — cloning from GitHub (shallow)..."
        mkdir -p "$(dirname "${CUTLASS_SRC_DIR}")"
        git clone --depth=1 \
            https://github.com/NVIDIA/cutlass.git "${CUTLASS_SRC_DIR}"
    fi

    log_ok "CUTLASS shallow clone complete: ${CUTLASS_SRC_DIR}"
    log_info "To get full history later, run:"
    log_info "  cd ${CUTLASS_SRC_DIR} && git fetch --unshallow"

    # Read version from source
    local cutlass_ver
    cutlass_ver=$(grep -E "^#define CUTLASS_(MAJOR|MINOR|PATCH)" \
        "${CUTLASS_SRC_DIR}/include/cutlass/version.h" \
        | awk '{print $3}' | tr '\n' '.' | sed 's/\.$//')

    # Skip if already installed at this version
    local installed_ver_file="${CUTLASS_INSTALL_DIR}/.cutlass_version"
    if [[ -f "${installed_ver_file}" ]] && [[ "$(cat "${installed_ver_file}")" == "${cutlass_ver}" ]]; then
        log_ok "CUTLASS ${cutlass_ver} headers already installed at ${CUTLASS_INSTALL_DIR}, skipping."
        return 0
    fi

    log_info "CUTLASS source version: ${cutlass_ver}"
    log_info "Install prefix: ${CUTLASS_INSTALL_DIR}"

    # cmake configure to generate cmake config files (no compilation)
    local build_dir
    build_dir=$(mktemp -d /tmp/cutlass-build-XXXXXX)

    cmake -S "${CUTLASS_SRC_DIR}" -B "${build_dir}" \
        -DCMAKE_INSTALL_PREFIX="${CUTLASS_INSTALL_DIR}" \
        -DCUTLASS_ENABLE_TESTS=OFF \
        -DCUTLASS_ENABLE_EXAMPLES=OFF \
        -DCUTLASS_ENABLE_DOCS=OFF \
        -DCUDA_TOOLKIT_ROOT_DIR="${CUDA_INSTALL_DIR}" \
        -DCMAKE_CUDA_COMPILER="${CUDA_INSTALL_DIR}/bin/nvcc" \
        -DCMAKE_CUDA_ARCHITECTURES=86 \
        2>&1 | tail -3

    # Copy headers directly (cmake --install requires libcutlass.so which is not built)
    mkdir -p "${CUTLASS_INSTALL_DIR}/include"
    cp -a "${CUTLASS_SRC_DIR}/include/cutlass" "${CUTLASS_INSTALL_DIR}/include/"
    cp -a "${CUTLASS_SRC_DIR}/include/cute"    "${CUTLASS_INSTALL_DIR}/include/"

    # Copy cmake config files from build dir
    mkdir -p "${CUTLASS_INSTALL_DIR}/lib/cmake/NvidiaCutlass"
    find "${build_dir}" -name "NvidiaCutlass*.cmake" \
        -exec cp {} "${CUTLASS_INSTALL_DIR}/lib/cmake/NvidiaCutlass/" \;

    rm -rf "${build_dir}"

    # Record installed version
    echo "${cutlass_ver}" > "${installed_ver_file}"

    log_ok "CUTLASS ${cutlass_ver} headers installed at ${CUTLASS_INSTALL_DIR}"
    log_ok "  include:    ${CUTLASS_INSTALL_DIR}/include/{cutlass,cute}"
    log_ok "  cmake:      ${CUTLASS_INSTALL_DIR}/lib/cmake/NvidiaCutlass"
    log_ok "  Usage:      cmake -DCMAKE_PREFIX_PATH=${CUTLASS_INSTALL_DIR} ..."
}

# ── Step 6: cuda-tile ─────────────────────────────────────────────────────────
install_cuda_tile() {
    log_info "Step 6/6: Installing cuda-tile..."

    run_as_user "PYENV_ROOT='${pyenv_root}' PATH='${pyenv_root}/bin:${pyenv_root}/shims:/usr/bin:/bin:\$PATH' pip install cuda-tile"
    log_ok "cuda-tile installed."
}

# ── Verification ──────────────────────────────────────────────────────────────
verify_env() {
    log_info "Verifying environment against cuTile requirements..."
    local fail=0

    # Driver version
    local driver_ver
    driver_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "")
    local driver_major
    driver_major=$(echo "${driver_ver}" | cut -d. -f1)
    if [[ "${driver_major}" =~ ^[0-9]+$ ]] && [[ "${driver_major}" -ge 580 ]]; then
        log_ok "Driver:    ${driver_ver}  (>= R580, target 590.44.01)"
    else
        log_fail "Driver:    ${driver_ver:-N/A}  (REQUIRED >= R580)"
        fail=1
    fi

    # CUDA version (add CUDA bin to PATH so nvcc is found before env is sourced)
    local cuda_ver
    cuda_ver=$(PATH="${CUDA_INSTALL_DIR}/bin:${PATH}" nvcc --version 2>/dev/null \
        | grep -oP 'release \K[0-9]+\.[0-9]+' || echo "")
    local cuda_major cuda_minor
    cuda_major=$(echo "${cuda_ver}" | cut -d. -f1)
    cuda_minor=$(echo "${cuda_ver}" | cut -d. -f2)
    if [[ "${cuda_major}" =~ ^[0-9]+$ ]] && \
       { [[ "${cuda_major}" -gt 13 ]] || [[ "${cuda_major}" -eq 13 && "${cuda_minor}" -ge 1 ]]; }; then
        log_ok "CUDA:      ${cuda_ver}  (>= 13.1)"
    else
        log_fail "CUDA:      ${cuda_ver:-N/A}  (REQUIRED >= 13.1)"
        fail=1
    fi

    # cuDNN version
    local cudnn_ver=""
    if [[ -f /usr/include/cudnn_version.h ]]; then
        local major minor patch
        major=$(grep "CUDNN_MAJOR"      /usr/include/cudnn_version.h | awk '{print $3}')
        minor=$(grep "CUDNN_MINOR"      /usr/include/cudnn_version.h | awk '{print $3}')
        patch=$(grep "CUDNN_PATCHLEVEL" /usr/include/cudnn_version.h | awk '{print $3}')
        cudnn_ver="${major}.${minor}.${patch}"
    fi
    local cudnn_cuda_pkg
    cudnn_cuda_pkg=$(dpkg -l "libcudnn9-cuda-${CUDNN_CUDA_MAJOR}" 2>/dev/null | awk '/^ii/{print $3}')
    if [[ -n "${cudnn_cuda_pkg}" ]]; then
        log_ok "cuDNN:     ${cudnn_ver}  (for CUDA ${CUDNN_CUDA_MAJOR}, package ${cudnn_cuda_pkg})"
    else
        log_fail "cuDNN:     ${cudnn_ver:-N/A}  (REQUIRED libcudnn9-cuda-${CUDNN_CUDA_MAJOR})"
        fail=1
    fi

    # Python version (via pyenv)
    local py_ver
    py_ver=$(run_as_user "PYENV_ROOT='${pyenv_root}' PATH='${pyenv_root}/bin:${pyenv_root}/shims:/usr/bin:/bin:\$PATH' python --version 2>/dev/null" \
        | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    local py_major py_minor
    py_major=$(echo "${py_ver}" | cut -d. -f1)
    py_minor=$(echo "${py_ver}" | cut -d. -f2)
    if [[ "${py_major}" =~ ^[0-9]+$ ]] && [[ "${py_major}" -ge 3 && "${py_minor}" -ge 10 ]]; then
        log_ok "Python:    ${py_ver}  (>= 3.10)"
    else
        log_fail "Python:    ${py_ver:-N/A}  (REQUIRED >= 3.10)"
        fail=1
    fi

    # cuda-tile
    if run_as_user "PYENV_ROOT='${pyenv_root}' PATH='${pyenv_root}/bin:${pyenv_root}/shims:/usr/bin:/bin:\$PATH' python -c 'import cuda.tile'" 2>/dev/null; then
        log_ok "cuda-tile: installed"
    else
        log_fail "cuda-tile: NOT installed  (run: pip install cuda-tile)"
        fail=1
    fi

    # CUTLASS CuTe DSL
    # CUTLASS C++ headers
    local cutlass_install="${CUTLASS_INSTALL_DIR}"
    local cutlass_ver_file="${cutlass_install}/.cutlass_version"
    if [[ -f "${cutlass_ver_file}" ]]; then
        log_ok "CUTLASS:   $(cat "${cutlass_ver_file}")  (headers at ${cutlass_install}/include)"
    else
        log_fail "CUTLASS:   NOT installed  (run: install_cutlass)"
        fail=1
    fi

    if [[ ${fail} -ne 0 ]]; then
        echo ""
        log_fail "One or more requirements are not met. If driver was just upgraded, reboot and re-run this script."
        exit 1
    else
        echo ""
        log_ok "All cuTile requirements satisfied."
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
FORCE=0    # set to 1 by --force to skip confirmation prompt
VERBOSE=0  # set to 1 by --verbose to show full apt output

parse_options() {
    local -n _cuda_ver="$1"   # nameref → caller's variable
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cuda-version)
                _cuda_ver="${2:?'--cuda-version requires a value (13.1.0 or 13.3.1)'}"
                shift 2
                ;;
            --cuda-version=*)
                _cuda_ver="${1#*=}"
                shift
                ;;
            -f|--force)
                FORCE=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--cuda-version <13.1.0|13.3.1>] [--force] [--verbose]"
                echo "  --cuda-version  CUDA Toolkit version to install (default: 13.1.0)"
                echo "                  13.1.0  →  CUDA 13.1.0  +  driver 590.44.01"
                echo "                  13.3.1  →  CUDA 13.3.1  +  driver 610.43.02"
                echo "  -f, --force     Skip confirmation prompt"
                echo "  -v, --verbose   Show full apt output"
                exit 0
                ;;
            *)
                log_fail "Unknown option: $1  (use --help)"
                exit 1
                ;;
        esac
    done
}

main() {
    local cuda_ver="13.1.0"   # default
    parse_options cuda_ver "$@"
    configure_versions "${cuda_ver}"

    require_root
    upgrade_python
    # upgrade_driver
    upgrade_cuda
    upgrade_cudnn
    install_cutlass
    install_cuda_tile

    verify_env
}

main "$@"
