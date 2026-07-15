#!/usr/bin/env bash
#
# collect-gpu-env.sh — Collect GPU environment information for cuTile
# Gathers: OS, kernel, NVIDIA driver, CUDA, Python (pyenv), cuda-tile, GPU hardware
#
set -uo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────
log_section() { echo ""; echo "── $* ──────────────────────────────────────────"; }
log_item()    { printf "  %-24s %s\n" "$1" "$2"; }
log_ok()      { printf "  %-24s \e[32m%s\e[0m\n" "$1" "$2"; }
log_warn()    { printf "  %-24s \e[33m%s\e[0m\n" "$1" "$2"; }
log_fail()    { printf "  %-24s \e[31m%s\e[0m\n" "$1" "$2"; }

# Set by configure_versions()
CUDA_VERSION=""
CUDA_VERSION_SHORT=""
CUDA_VERSION_MAJOR=""
CUDA_VERSION_MINOR=""
CUDA_INSTALL_DIR=""
CUDA_PROFILE_SH=""
NVIDIA_DRIVER_VERSION=""
NVIDIA_DRIVER_URL=""
NVIDIA_DRIVER_ARCHIVE_URL="https://www.nvidia.com/en-us/drivers/"
CUDA_INSTALLER=""
CUDA_URL=""
CUDA_ARCHIVE_URL="https://developer.nvidia.com/cuda-toolkit-archive"
CUDNN_CUDA_MAJOR=""
CUDNN_VERSION=""   # set by configure_versions()
CUDNN_DEB=""
CUDNN_URL=""
CUDNN_ARCHIVE_URL="https://developer.nvidia.com/cudnn-archive"
PYTHON_VERSION_MIN="3.10"
CUTLASS_SRC_DIR="${HOME}/workspace/cuda-dev/cutlass"
CUTLASS_URL="https://github.com/NVIDIA/cutlass.git"
CUTILE_CPP_CUDA_MIN="13.3"
CUTILE_PYTHON_PYPI_URL="https://pypi.org/project/cuda-tile/"
CUTILE_PYTHON_SOURCE_URL="https://github.com/nvidia/cutile-python"
CUTILE_PYTHON_DOCS_URL="https://docs.nvidia.com/cuda/cutile-python"
CUTILE_CPP_DOCS_URL="https://docs.nvidia.com/cuda/cutile-cpp"
CUTILE_CPP_SAMPLES_URL="https://github.com/NVIDIA/cuda-samples/tree/master/Samples/9_CUDA_Tile"
pyenv_root="${HOME}/.pyenv"

# https://docs.nvidia.com/cuda/cuda-toolkit-release-notes
# https://docs.nvidia.com/deeplearning/cudnn/backend/latest/reference/support-matrix.html
#  ┌─────────────────────┬─────────────────┬──────────┬──────────┐
#  │    CUDA Toolkit     │   最低驱动版本  │  cuDNN   │  Python  │
#  ├─────────────────────┼─────────────────┼──────────┼──────────┤
#  │ 13.3 GA / Update 1  │ >= 610.43.02    │ 9.24.0   │ >= 3.10  │
#  │ 13.1 GA             │ >= 590.44.01    │ 9.19.0   │ >= 3.10  │
#  │ 13.0 GA             │ >= 580.65.06    │ 9.x      │ >= 3.10  │
#  │ 12.9 GA             │ >= 575.51.03    │ 9.x      │ >= 3.10  │
#  │ 12.8 GA             │ >= 570.26.06    │ 8.9.x    │ >= 3.10  │
#  └─────────────────────┴─────────────────┴──────────┴──────────┘

# ── Version lookup tables ──────────────────────────────────────────────────────
# Key: CUDA full version (x.y.z)  Value: "DRIVER_VERSION CUDNN_VERSION PYTHON_VERSION"
declare -A CUDA_VERSION_MAP=(
    ["13.1.0"]="590.44.01 9.19.0 3.10.0"
    ["13.3.1"]="610.43.02 9.24.0 3.10.0"
)

configure_versions() {
    local cuda_ver="$1"
    local entry="${CUDA_VERSION_MAP[${cuda_ver}]:-}"
    if [[ -z "${entry}" ]]; then
        echo "Error: unsupported cuda-version '${cuda_ver}'. Valid options: ${!CUDA_VERSION_MAP[*]}" >&2
        exit 1
    fi
    CUDA_VERSION="${cuda_ver}"
    read -ra _fields <<< "${entry}"
    NVIDIA_DRIVER_VERSION="${_fields[0]}"
    CUDNN_VERSION="${_fields[1]}"
    PYTHON_VERSION_MIN="${_fields[2]%.*}"   # 3.10.0 → 3.10

    CUDA_VERSION_SHORT="${CUDA_VERSION%.*}"
    CUDA_VERSION_MAJOR="${CUDA_VERSION_SHORT%.*}"
    CUDA_VERSION_MINOR="${CUDA_VERSION_SHORT#*.}"
    CUDA_INSTALL_DIR="/usr/local/cuda-${CUDA_VERSION_SHORT}"
    CUDA_PROFILE_SH="/etc/profile.d/cuda-${CUDA_VERSION_SHORT}.sh"
    CUDNN_CUDA_MAJOR="${CUDA_VERSION_MAJOR}"
    NVIDIA_DRIVER_URL="https://download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
    CUDA_INSTALLER="cuda_${CUDA_VERSION}_${NVIDIA_DRIVER_VERSION}_linux.run"
    CUDA_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_INSTALLER}"
    CUDNN_DEB="cudnn-local-repo-ubuntu2204-${CUDNN_VERSION}_1.0-1_amd64.deb"
    CUDNN_URL="https://developer.download.nvidia.com/compute/cudnn/${CUDNN_VERSION}/local_installers/${CUDNN_DEB}"
}

parse_options() {
    local -n _cuda_ver="$1"
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
            -h|--help)
                echo "Usage: $0 [--cuda-version <13.1.0|13.3.1>]"
                echo "  --cuda-version  Target CUDA version to report against"
                echo "                  Auto-detected from ~/.bashrc CUDA_VERSION if omitted"
                echo "                  Valid options: ${!CUDA_VERSION_MAP[*]}"
                exit 1
                ;;
            *)
                echo "Unknown option: $1  (use --help)" >&2
                exit 1
                ;;
        esac
    done
}

# ── OS & Kernel ───────────────────────────────────────────────────────────────
collect_os() {
    log_section "OS & Kernel"
    log_item "OS:" "$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"' || echo 'unknown')"
    log_item "Kernel:" "$(uname -r)"
    log_item "Arch:" "$(uname -m)"
    log_item "Hostname:" "$(hostname)"
}

# ── NVIDIA Driver ─────────────────────────────────────────────────────────────
collect_driver() {
    log_section "NVIDIA Driver"
    log_item "Download:" "${NVIDIA_DRIVER_URL}"
    log_item "Website:" "https://www.nvidia.com/en-us/drivers/"
    log_item "Expected:"        "${NVIDIA_DRIVER_VERSION}"

    # installed: version on disk (modinfo reads the .ko file, present even before reboot)
    local installed_ver=""
    installed_ver=$(modinfo nvidia 2>/dev/null | awk '/^version:/{print $2}')

    # loaded: version currently running in the kernel (/proc only exists when module is loaded)
    local loaded_ver=""
    loaded_ver=$(grep -oP '\b[0-9]{3}\.[0-9]+\.[0-9]+\b' \
        /proc/driver/nvidia/version 2>/dev/null | head -1 || echo "")

    if [[ -n "${installed_ver}" ]]; then
        if [[ "${installed_ver}" == "${NVIDIA_DRIVER_VERSION}" ]]; then
            log_ok   "Installed (.ko):" "${installed_ver}  (== expected ✓)"
        else
            log_fail "Installed (.ko):" "${installed_ver}  (expected ${NVIDIA_DRIVER_VERSION})"
        fi
    else
        log_fail "Installed (.ko):" "not found  (run: nvidia-driver-install.sh)"
    fi

    if [[ -z "${loaded_ver}" ]]; then
        log_fail "Loaded (kernel):" "not loaded  (reboot required)"
    elif [[ "${loaded_ver}" == "${NVIDIA_DRIVER_VERSION}" ]]; then
        log_ok   "Loaded (kernel):" "${loaded_ver}  (== expected ✓)"
    else
        log_fail "Loaded (kernel):" "${loaded_ver}  (expected ${NVIDIA_DRIVER_VERSION} — reboot required)"
    fi

    # CUDA Compute Capability reported by nvidia-smi
    local compute_cap
    compute_cap=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 || echo "")
    [[ -n "${compute_cap}" ]] && log_item "Compute cap:" "${compute_cap}"
}

# ── CUDA Toolkit ──────────────────────────────────────────────────────────────
collect_cuda() {
    log_section "CUDA Toolkit"
    # CUDA Toolkit × 最低驱动版本 (Linux x86_64)
    local _cv="${CUDA_VERSION_SHORT}"
    echo ""
    echo "  ┌────────────────────┬─────────────────────────┐"
    echo "  │    CUDA Toolkit    │      最低驱动版本       │"
    echo "  ├────────────────────┼─────────────────────────┤"
    printf "  │ %-18s │ %-23s │\n" "13.3 GA / Update 1" ">= 610.43.02"
    printf "  │ %-18s │ %-23s │\n" "13.2 Update 1"      ">= 595.58.03"
    printf "  │ %-18s │ %-23s │\n" "13.2 GA"            ">= 595.45.04"
    printf "  │ %-18s │ %-23s │\n" "13.1 Update 1"      ">= 590.48.01"
    printf "  │ %-18s │ %-23s │\n" "13.1 GA"            ">= 590.44.01$( [[ "${_cv}" == "13.1" ]] && echo -n " <-" )"
    printf "  │ %-18s │ %-23s │\n" "13.0 GA"            ">= 580.65.06$( [[ "${_cv}" == "13.0" ]] && echo -n " <-" )"
    printf "  │ %-18s │ %-23s │\n" "12.9 GA"            ">= 575.51.03$( [[ "${_cv}" == "12.9" ]] && echo -n " <-" )"
    printf "  │ %-18s │ %-23s │\n" "12.8 GA"            ">= 570.26.06$( [[ "${_cv}" == "12.8" ]] && echo -n " <-" )"
    echo "  └────────────────────┴─────────────────────────┘"
    echo ""
    log_item "Release notes:" "https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/"
    log_item "Download:" "${CUDA_URL}"
    log_item "Website:" "${CUDA_ARCHIVE_URL}"

    local nvcc_path
    nvcc_path=$(PATH="${CUDA_INSTALL_DIR}/bin:${PATH}" command -v nvcc 2>/dev/null || echo "")

    if [[ -z "${nvcc_path}" ]]; then
        log_fail "nvcc:" "not found (expected at ${CUDA_INSTALL_DIR}/bin/nvcc)"
        return
    fi

    local cuda_ver
    cuda_ver=$(PATH="${CUDA_INSTALL_DIR}/bin:${PATH}" nvcc --version 2>/dev/null \
        | grep -oP 'release \K[0-9]+\.[0-9]+' || echo "")
    local cuda_major cuda_minor
    cuda_major=$(echo "${cuda_ver}" | cut -d. -f1)
    cuda_minor=$(echo "${cuda_ver}" | cut -d. -f2)

    if [[ "${cuda_major}" =~ ^[0-9]+$ ]] && \
       { [[ "${cuda_major}" -gt "${CUDA_VERSION_MAJOR}" ]] || \
         [[ "${cuda_major}" -eq "${CUDA_VERSION_MAJOR}" && "${cuda_minor}" -ge "${CUDA_VERSION_MINOR}" ]]; }; then
        log_ok  "CUDA version:" "${cuda_ver}  (>= ${CUDA_VERSION_SHORT} ✓)"
    else
        log_fail "CUDA version:" "${cuda_ver:-N/A}  (REQUIRED >= ${CUDA_VERSION_SHORT})"
    fi

    log_item "nvcc path:" "${nvcc_path}"
    log_item "include:" "${CUDA_INSTALL_DIR}/include"
    # Key headers
    for hdr in cuda.h cuda_runtime.h cublas.h cuda_tile.h; do
        [[ -f "${CUDA_INSTALL_DIR}/include/${hdr}" ]] && log_item "" "${hdr}"
    done
    log_item "lib64:" "${CUDA_INSTALL_DIR}/lib64"
    # Key runtime libraries
    while IFS= read -r lib; do
        log_item "" "$(basename "${lib}")"
    done < <(find "${CUDA_INSTALL_DIR}/lib64" -maxdepth 1 \
        -name "libcudart.so.*.*" -o -name "libcublas.so.*.*" \
        -o -name "libcufft.so.*.*" -o -name "libcurand.so.*.*" \
        2>/dev/null | sort -V)
}

# ── cuDNN ─────────────────────────────────────────────────────────────────────
collect_cudnn() {
    log_section "cuDNN"
    log_item "Download:" "${CUDNN_URL}"
    log_item "Website:" "${CUDNN_ARCHIVE_URL}"

    # Header is installed by libcudnn9-headers-cuda-XX into /usr/include/x86_64-linux-gnu/
    local ver_header="/usr/include/x86_64-linux-gnu/cudnn_version.h"
    # Fallback to legacy path (cuDNN installed via cuda-12 local repo)
    [[ ! -f "${ver_header}" ]] && ver_header="/usr/include/cudnn_version.h"
    local cudnn_ver=""
    if [[ -f "${ver_header}" ]]; then
        local major minor patch
        major=$(grep "^#define CUDNN_MAJOR "      "${ver_header}" | awk '{print $3}')
        minor=$(grep "^#define CUDNN_MINOR "      "${ver_header}" | awk '{print $3}')
        patch=$(grep "^#define CUDNN_PATCHLEVEL " "${ver_header}" | awk '{print $3}')
        cudnn_ver="${major}.${minor}.${patch}"
    fi

    # Check the dpkg package that binds cuDNN to the target CUDA major
    local pkg="libcudnn9-cuda-${CUDNN_CUDA_MAJOR}"
    local pkg_ver
    pkg_ver=$(dpkg -l "${pkg}" 2>/dev/null | awk '/^ii/{print $3}')

    if [[ -n "${pkg_ver}" ]]; then
        local display_ver="${cudnn_ver:-${pkg_ver%%-*}}"
        log_ok  "cuDNN version:" "${display_ver}  (${pkg} ${pkg_ver} ✓)"
    else
        if [[ -n "${cudnn_ver}" ]]; then
            log_warn "cuDNN version:" "${cudnn_ver}  (${pkg} not installed — wrong CUDA target?)"
        else
            log_fail "cuDNN version:" "not found  (run: apt install ${pkg})"
        fi
    fi

    # Show all installed libcudnn9-cuda-* packages for reference
    local all_cudnn
    all_cudnn=$(dpkg -l 'libcudnn9-cuda-*' 2>/dev/null | awk '/^ii/{print $2" "$3}')
    if [[ -n "${all_cudnn}" ]]; then
        while IFS= read -r line; do
            log_item "  installed:" "${line}"
        done <<< "${all_cudnn}"
    fi

    # Header location
    local include_dir="/usr/include/x86_64-linux-gnu"
    if [[ -f "${ver_header}" ]]; then
        log_item "  includes:" "${include_dir}"
        while IFS= read -r hdr; do
            log_item "" "$(basename "${hdr}")"
        done < <(find "${include_dir}" -maxdepth 1 -name "cudnn*.h" 2>/dev/null | sort)
    fi

    # Library location
    local lib_dir="/usr/lib/x86_64-linux-gnu"
    local lib_path
    lib_path=$(find "${lib_dir}" -name "libcudnn.so.*.*" 2>/dev/null | sort -V | tail -1)
    if [[ -n "${lib_path}" ]]; then
        log_item "  libs:" "${lib_dir}"
        while IFS= read -r lib; do
            log_item "" "$(basename "${lib}")"
        done < <(find "${lib_dir}" -name "libcudnn*.so.*.*" 2>/dev/null | sort -V)
    fi
}

# ── Python ────────────────────────────────────────────────────────────────────
collect_python() {
    log_section "Python (pyenv)"


    if [[ ! -d "${pyenv_root}" ]]; then
        log_fail "pyenv:" "not found at ${pyenv_root}"
    else
        local pyenv_ver
        pyenv_ver=$(PYENV_ROOT="${pyenv_root}" "${pyenv_root}/bin/pyenv" --version 2>/dev/null || echo "unknown")
        log_item "pyenv:" "${pyenv_ver}"

        local global_ver
        global_ver=$(PYENV_ROOT="${pyenv_root}" "${pyenv_root}/bin/pyenv" global 2>/dev/null || echo "unknown")
        log_item "pyenv global:" "${global_ver}"
    fi

    local py_ver
    py_ver=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
        python --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    local py_major py_minor
    py_major=$(echo "${py_ver}" | cut -d. -f1)
    py_minor=$(echo "${py_ver}" | cut -d. -f2)

    if [[ "${py_major}" =~ ^[0-9]+$ ]] && [[ "${py_major}" -ge 3 && "${py_minor}" -ge 10 ]]; then
        log_ok  "Python version:" "${py_ver}  (>= ${PYTHON_VERSION_MIN} ✓)"
    else
        log_fail "Python version:" "${py_ver:-N/A}  (REQUIRED >= ${PYTHON_VERSION_MIN})"
    fi

    local py_path
    py_path=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
        command -v python 2>/dev/null || echo "")
    [[ -n "${py_path}" ]] && log_item "Python path:" "${py_path}"

    local pip_ver
    pip_ver=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
        pip --version 2>/dev/null || echo "")
    [[ -n "${pip_ver}" ]] && log_item "pip:" "${pip_ver}"
}

# ── cuda-tile ─────────────────────────────────────────────────────────────────
collect_cuda_tile() {
    log_section "cuda-tile"

    # Comparison table
    echo "  ┌───────────┬─────────────────────────────────┬───────────────────┐"
    echo "  │           │          cuTile Python          │    cuTile C++     │"
    echo "  ├───────────┼─────────────────────────────────┼───────────────────┤"
    echo "  │ 来源      │ PyPI / GitHub                   │ CUDA Toolkit 内置 │"
    echo "  ├───────────┼─────────────────────────────────┼───────────────────┤"
    echo "  │ 仓库      │ ${CUTILE_PYTHON_SOURCE_URL##https://} │ 无独立仓库        │"
    echo "  ├───────────┼─────────────────────────────────┼───────────────────┤"
    printf "  │ 最低 CUDA │ %-31s │ %-17s │\n" "13.1" "${CUTILE_CPP_CUDA_MIN}"
    echo "  └───────────┴─────────────────────────────────┴───────────────────┘"
    echo ""

    # cuTile Python
    log_item "  [Python]" ""
    log_item "  pypi:"    "${CUTILE_PYTHON_PYPI_URL}"
    log_item "  source:"  "${CUTILE_PYTHON_SOURCE_URL}"
    log_item "  docs:"    "${CUTILE_PYTHON_DOCS_URL}"

    if PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
            python -c 'import cuda.tile' 2>/dev/null; then
        local tile_ver tile_path
        tile_ver=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
            python -c 'import cuda.tile; print(getattr(cuda.tile, "__version__", "installed"))' 2>/dev/null || echo "installed")
        tile_path=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
            python -c 'import cuda.tile, os; print(os.path.dirname(cuda.tile.__file__))' 2>/dev/null || echo "")
        log_ok  "  cuda-tile:"  "${tile_ver}"
        [[ -n "${tile_path}" ]] && log_item "  location:" "${tile_path}"
    else
        log_fail "  cuda-tile:" "NOT installed  (run: pip install cuda-tile)"
    fi

    # cuTile C++ (built into CUDA Toolkit >= 13.3)
    echo ""
    log_item "  [C++]"    ""
    log_item "  docs:"    "${CUTILE_CPP_DOCS_URL}"
    log_item "  samples:" "${CUTILE_CPP_SAMPLES_URL}"
    log_item "  req:"     "CUDA Toolkit >= ${CUTILE_CPP_CUDA_MIN}  (current: ${CUDA_VERSION_SHORT})"

    local cutile_cpp_header="${CUDA_INSTALL_DIR}/include/cuda_tile.h"
    if [[ -f "${cutile_cpp_header}" ]]; then
        log_ok  "  cuTile C++:"  "available  (${cutile_cpp_header})"
    else
        log_warn "  cuTile C++:" "not found  (requires CUDA >= ${CUTILE_CPP_CUDA_MIN}, current ${CUDA_VERSION_SHORT})"
    fi
}

# ── CUTLASS C++ headers ───────────────────────────────────────────────────────
collect_cutlass() {
    log_section "CUTLASS C++ Headers"
    log_item "Download:" "${CUTLASS_URL}"

    # CUTLASS C++ headers — installed into CUDA toolkit root
    local install_dir="${CUDA_INSTALL_DIR}"
    local ver_file="${install_dir}/.cutlass_version"

    if [[ -f "${ver_file}" ]]; then
        log_ok  "CUTLASS version:" "$(cat "${ver_file}")"
        log_item "  install dir:" "${install_dir}"
        log_item "  include:" "${install_dir}/include"
        # Verify key headers exist
        local cutlass_h="${install_dir}/include/cutlass/cutlass.h"
        local cute_h="${install_dir}/include/cute/tensor.hpp"
        [[ -f "${cutlass_h}" ]] && log_item "  cutlass.h:" "${cutlass_h}"
        [[ -f "${cute_h}" ]]    && log_item "  cute/tensor.hpp:" "${cute_h}"
        local cmake_dir="${install_dir}/lib/cmake/NvidiaCutlass"
        if [[ -d "${cmake_dir}" ]]; then
            log_item "  cmake config:" "${cmake_dir}"
            local cmake_files
            cmake_files=$(ls "${cmake_dir}"/*.cmake 2>/dev/null | xargs -I{} basename {} | tr '\n' '  ')
            [[ -n "${cmake_files}" ]] && log_item "  cmake files:" "${cmake_files}"
        fi
    else
        log_fail "CUTLASS headers:" "not installed  (run: upgrade-gpu-env.sh → install_cutlass)"
    fi

    # Source tree version
    local src_ver_h="${CUTLASS_SRC_DIR}/include/cutlass/version.h"
    if [[ -f "${src_ver_h}" ]]; then
        local src_major src_minor src_patch
        src_major=$(grep "^#define CUTLASS_MAJOR" "${src_ver_h}" | awk '{print $3}')
        src_minor=$(grep "^#define CUTLASS_MINOR" "${src_ver_h}" | awk '{print $3}')
        src_patch=$(grep "^#define CUTLASS_PATCH"  "${src_ver_h}" | awk '{print $3}')
        log_item "  source tree:" "${src_major}.${src_minor}.${src_patch}  (${CUTLASS_SRC_DIR})"
    fi
}


collect_gpu_hardware() {
    log_section "GPU Hardware"

    if ! command -v nvidia-smi &>/dev/null; then
        log_fail "nvidia-smi:" "not found"
        return
    fi

    # Per-GPU details
    local gpu_info
    gpu_info=$(nvidia-smi --query-gpu=index,name,compute_cap,memory.total,pcie.link.gen.current,pcie.link.width.current \
        --format=csv,noheader 2>/dev/null || echo "")

    if [[ -z "${gpu_info}" ]]; then
        log_warn "GPUs:" "none detected"
        return
    fi

    local gpu_count=0
    while IFS=',' read -r idx name compute mem pcie_gen pcie_width; do
        idx=$(echo "${idx}" | xargs)
        name=$(echo "${name}" | xargs)
        compute=$(echo "${compute}" | xargs)
        mem=$(echo "${mem}" | xargs)
        pcie_gen=$(echo "${pcie_gen}" | xargs)
        pcie_width=$(echo "${pcie_width}" | xargs)
        echo ""
        log_item "GPU ${idx}:" "${name}"
        log_item "  Compute cap:" "${compute}"
        log_item "  Memory:" "${mem}"
        log_item "  PCIe:" "Gen${pcie_gen} x${pcie_width}"
        gpu_count=$(( gpu_count + 1 ))
    done <<< "${gpu_info}"

    echo ""
    log_item "Total GPUs:" "${gpu_count}"

    # nvidia-smi summary table
    echo ""
    nvidia-smi 2>/dev/null | grep -E "^\|" | head -20 || true
}

# ── Environment Variables ─────────────────────────────────────────────────────
collect_env_vars() {
    log_section "Environment Variables"
    for var in CUDA_VERSION CUDA_HOME LD_LIBRARY_PATH PATH PYENV_ROOT; do
        local val="${!var:-}"
        if [[ -n "${val}" ]]; then
            # Truncate long PATH-style vars for readability
            if [[ "${#val}" -gt 80 ]]; then
                val="${val:0:77}..."
            fi
            log_item "${var}:" "${val}"
        else
            case "${var}" in
                CUDA_HOME|CUDA_PATH)
                    log_warn "${var}:" "(not set — source ~/.bashrc or ${CUDA_PROFILE_SH})"
                    ;;
                *)
                    log_item "${var}:" "(not set)"
                    ;;
            esac
        fi
    done
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    log_section "CUDA Development Environment Summary"

    local pass=0 fail=0

    # Driver
    local driver_ver driver_major
    driver_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "")
    driver_major=$(echo "${driver_ver}" | cut -d. -f1)
    if [[ "${driver_major}" =~ ^[0-9]+$ ]] && [[ "${driver_major}" -ge 580 ]]; then
        log_ok  "Driver >= R580:" "PASS  (${driver_ver})"
        pass=$(( pass + 1 ))
    else
        log_fail "Driver >= R580:" "FAIL  (${driver_ver:-N/A})"
        fail=$(( fail + 1 ))
    fi

    # CUDA
    local cuda_ver cuda_major cuda_minor
    cuda_ver=$(PATH="${CUDA_INSTALL_DIR}/bin:${PATH}" nvcc --version 2>/dev/null \
        | grep -oP 'release \K[0-9]+\.[0-9]+' || echo "")
    cuda_major=$(echo "${cuda_ver}" | cut -d. -f1)
    cuda_minor=$(echo "${cuda_ver}" | cut -d. -f2)
    if [[ "${cuda_major}" =~ ^[0-9]+$ ]] && \
       { [[ "${cuda_major}" -gt "${CUDA_VERSION_MAJOR}" ]] || \
         [[ "${cuda_major}" -eq "${CUDA_VERSION_MAJOR}" && "${cuda_minor}" -ge "${CUDA_VERSION_MINOR}" ]]; }; then
        log_ok  "CUDA >= ${CUDA_VERSION_SHORT}:" "PASS  (${cuda_ver})"
        pass=$(( pass + 1 ))
    else
        log_fail "CUDA >= ${CUDA_VERSION_SHORT}:" "FAIL  (${cuda_ver:-N/A})"
        fail=$(( fail + 1 ))
    fi

    # cuDNN
    local cudnn_pkg="libcudnn9-cuda-${CUDNN_CUDA_MAJOR}"
    local cudnn_pkg_ver
    cudnn_pkg_ver=$(dpkg -l "${cudnn_pkg}" 2>/dev/null | awk '/^ii/{print $3}')
    if [[ -n "${cudnn_pkg_ver}" ]]; then
        log_ok  "cuDNN (cuda-${CUDNN_CUDA_MAJOR}):" "PASS  (${cudnn_pkg_ver})"
        pass=$(( pass + 1 ))
    else
        log_fail "cuDNN (cuda-${CUDNN_CUDA_MAJOR}):" "FAIL  (run: apt install ${cudnn_pkg})"
        fail=$(( fail + 1 ))
    fi

    # Python
    local py_ver py_major py_minor
    py_ver=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
        python --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    py_major=$(echo "${py_ver}" | cut -d. -f1)
    py_minor=$(echo "${py_ver}" | cut -d. -f2)
    if [[ "${py_major}" =~ ^[0-9]+$ ]] && [[ "${py_major}" -ge 3 && "${py_minor}" -ge 10 ]]; then
        log_ok  "Python >= ${PYTHON_VERSION_MIN}:" "PASS  (${py_ver})"
        pass=$(( pass + 1 ))
    else
        log_fail "Python >= ${PYTHON_VERSION_MIN}:" "FAIL  (${py_ver:-N/A})"
        fail=$(( fail + 1 ))
    fi

    # cuda-tile
    local tile_ver
    tile_ver=$(PYENV_ROOT="${pyenv_root}" PATH="${pyenv_root}/bin:${pyenv_root}/shims:${PATH}" \
        python -c 'import cuda.tile; print(getattr(cuda.tile, "__version__", ""))' 2>/dev/null || echo "")
    if [[ -n "${tile_ver}" ]]; then
        log_ok  "cuda-tile:" "PASS  (${tile_ver})"
        pass=$(( pass + 1 ))
    else
        log_fail "cuda-tile:" "FAIL  (run: pip install cuda-tile)"
        fail=$(( fail + 1 ))
    fi

    # CUTLASS C++ headers
    if [[ -f "${CUDA_INSTALL_DIR}/.cutlass_version" ]]; then
        log_ok  "CUTLASS headers:" "PASS  ($(cat "${CUDA_INSTALL_DIR}/.cutlass_version"))"
        pass=$(( pass + 1 ))
    else
        log_fail "CUTLASS headers:" "FAIL  (run upgrade-gpu-env.sh → install_cutlass)"
        fail=$(( fail + 1 ))
    fi

    echo ""
    if [[ ${fail} -eq 0 ]]; then
        echo "  ✓ All ${pass} requirements satisfied — environment is ready for cuTile."
    else
        echo "  ✗ ${fail} requirement(s) not met. Run upgrade-gpu-env.sh to fix."
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
resolve_cuda_version() {
    local -n _ver="$1"   # nameref to caller's variable

    # 1. Read CUDA_VERSION from ~/.bashrc managed block
    local bashrc_ver=""
    if [[ -f "${HOME}/.bashrc" ]]; then
        bashrc_ver=$(grep -oP '(?<=^export CUDA_VERSION=)[^\s]+' "${HOME}/.bashrc" | tail -1)
    fi
    if [[ -n "${bashrc_ver}" ]]; then
        echo "[INFO] Auto-detected CUDA_VERSION=${bashrc_ver} from ~/.bashrc"
        _ver="${bashrc_ver}"
        return
    fi

    # 2. Prompt user
    echo ""
    echo "  CUDA version not found in ~/.bashrc and not supplied via --cuda-version."
    echo "  Valid options: ${!CUDA_VERSION_MAP[*]}"
    read -r -p "  Enter CUDA version: " _ver
    # parse_options _ver "$@"
    echo ""
}

main() {
    local cuda_ver=""
    parse_options cuda_ver "$@"
    if [[ -z "${cuda_ver}" ]]; then
        resolve_cuda_version cuda_ver
    fi
    configure_versions "${cuda_ver}"

    echo "=================================================="
    echo "  GPU Environment Report"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')  |  $(hostname)"
    echo "=================================================="
    
    print_summary
    collect_os
    collect_driver
    collect_cuda
    collect_cudnn
    collect_cuda_tile
    collect_cutlass
    collect_python
    collect_gpu_hardware
    collect_env_vars

    echo ""
}

main "$@"
