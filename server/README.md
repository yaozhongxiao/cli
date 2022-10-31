## Local Web Server

Here are some options to quickly spin up a local web server to let your browser render local files.

### 1. Python 3
Do the same steps, but use the following command 
instead
```
python3 -m http.server
```

### 2. VSCode
If you are using Visual Studio Code you can install the Live Server extension which provides a local web server enviroment.
[Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)

### 3. Node.js
Alternatively, if you demand a more responsive setup and already use nodejs

- Install http-server by typing ```npm install -g http-server```

- Change into your working directory, where yoursome.html lives

- Start your http server by issuing ```http-server -c-1```

This spins up a Node.js httpd which serves the files in your directory as static files accessible from http://localhost:8080 

### 4. Ruby
If your preferred language is Ruby ... the Ruby Gods say this works as well:

```
ruby -run -e httpd . -p 8080
```

### 5. PHP
Of course PHP also has its solution.
```
php -S localhost:8000
```

## Reference 
[1].  https://stackoverflow.com/questions/10752055/cross-origin-requests-are-only-supported-for-http-error-when-loading-a-local