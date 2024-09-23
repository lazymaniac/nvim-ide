# Kulala Cheat Sheet



---

## Authentication

In general, you can use the Authorization header to send an authentication token to the server. The content of the header depends on the type of authentication you are using.


### Basic Authentication

Basic authentication needs a Base64 encoded string of username:password as the value of the Authorization header.

If given it'll be directly used in the HTTP request:

```http
GET https://www/api HTTP/1.1
Authorization: Basic TXlVc2VyOlByaXZhdGU=
```

Furthermore you can enter username and password in plain text in the Authorization header field, Kulala will automatically encode it for you.

There will be two possible ways to enter the credentials:

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}}:{{Password}}
```

or

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}} {{Password}}
```


### Digest Authentication

Digest is implemented the same way as Basic authentication.

You can enter the username:password in plain text

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}}:{{Password}}
```

or username password

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}} {{Password}}
```


### NTLM Authentication

For NTLM authentication, you need to provide the username and password the same way:

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}}:{{Password}}
```

or

```http
GET https://www/api HTTP/1.1
Authorization: Basic {{Username}} {{Password}}
```


### Negotiate

This is a SPNEGO-based implementation, which doesn't need username and password, but uses the default credentials.

```http
GET https://www/api HTTP/1.1
Authorization: Negotiate
```


### Bearer Token

For a Bearer Token you need to send your credentials to an authentication endpoint and receive a token in return.

This token is then used in the Authorization header for further requests.

Sending the credentials
```http
# @name login
POST {{loginURL}} HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Accept: application/json

client_id={{ClientId}}&client_secret={{ClientSecret}}&grant_type=client_credentials&scope={{Scope}}
```

This is a login named request with the credentials and the result may look like

```json
{
  "token_type": "Bearer",
  "expires_in": 3599,
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1Ni....."
}
```

with the request variables feature from Kulala you can now access the access_token and use it in the next requests.

```http
GET {{apiURL}}/items HTTP/1.1
Accept: application/json
Authorization: Bearer {{login.response.body.$.access_token}}
```


### AWS Signature V4

Amazon Web Services (AWS) Signature version 4 is a protocol for authenticating requests to AWS services.
AWS Signature version 4 authenticates requests to AWS services. To use it you need to set the Authorization header schema to AWS and provide your AWS credentials separated by spaces:

```text
<access-key-id>: AWS Access Key Id
<secret-access-key>: AWS Secret Access Key
token:<aws-session-token>: AWS Session Token - required only for temporary credentials
region:<region>: AWS Region
service:<service>: AWS Service
```

```http
GET {{apiUrl}}/ HTTP/1.1
Authorization: AWS <access-key-id> <secret-access-key> token:<aws-session-token> region:<region> service:<service>
```


---


## DotEnv and HTTP client environment variables support

Kulala supports environment variables in .http files.
It allows you to define environment variables in a .env file or in a http-client.env.json file (preferred) and reference them in your HTTP requests.
If you define the same environment variable in both the .env and the http-client.env.json file, the value from the http-client.env.json file will be used.
The order of the environment variables resolution is as follows:

1. System environment variables
2. http-client.env.json file
3. .env file

> note
> The usage of environment variables is optional, but if you want to use them, we would advise you to use the http-client.env.json file.

DotEnv is still supported, but it's not recommended, because it's not as flexible as the http-client.env.json file.


### http-client.env.json

You can also define environment variables via the http-client.env.json file.

Create a file http-client.env.json in the root of your .http files directory and define environment variables in it.

**http-client.env.json**
```json
{
  "dev": {
    "API_KEY": "your-api-key"
  },
  "testing": {
    "API_KEY": "your-api-key"
  },
  "staging": {
    "API_KEY": "your-api-key"
  },
  "prod": {
    "API_KEY": "your-api-key"
  }
}
```

The keys like dev, testing, staging, and prod are the environment names.
They can be used to switch between different environments.
You can freely define your own environment names. By default the dev environment is used.
This can be overridden by setting the default_env configuration option.
To change the environment, you can use the :lua require('kulala').set_selected_env('prod') command.

> tip
> You can also use the :lua require('kulala').set_selected_env() command to select an environment using a telescope prompt.

Then, you can reference the environment variables in your HTTP requests like this:

```http
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Authorization: Bearer {{API_KEY}}

{
  "name": "John"
}
```


#### Default http headers

You can define default HTTP headers in the http-client.env.json file.

You need to put them in the special _base property and the DEFAULT_HEADERS will be merged with the headers from the HTTP requests.

**http-client.env.json**
```json
{
  "_base": {
    "DEFAULT_HEADERS": {
      "Content-Type": "application/json",
      "Accept": "application/json"
  },
  "dev": {
    "API_KEY": "your-api-key"
  }
}
```

Then, they're automatically added to the HTTP requests, unless you override them.

```http
POST https://httpbin.org/post HTTP/1.1
Authorization: Bearer {{API_KEY}}

{
  "name": "John"
}
```


### DotEnv

You can create a .env file in the root of your .http files directory and define environment variables in it.
The file should look like this:

**.env**
```env
API_KEY=your-api-key
```

Then, you can reference the environment variables in your HTTP requests like this:

```http
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Authorization: Bearer {{API_KEY}}

{
  "name": "John"
}
```


---


## Request Variables

The definition syntax of request variables is just like a single-line comment, and follows # @name REQUEST_NAME just as metadata.

```http
# @name THIS_IS_AN_EXAMPLE_REQUEST_NAME
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/x-www-form-urlencoded

name=foo&password=bar
```

You can think of request variable as attaching a name metadata to the underlying request. This kind of requests can be called with Named Request.
Other requests can use THIS_IS_AN_EXAMPLE_REQUEST_NAME as an identifier to reference the expected part of the named request or its latest response.

> warning
> If you want to refer the response of a named request, you need to manually trigger the named request to retrieve its response first.
> Otherwise the plain text of variable reference like {{THIS_IS_AN_EXAMPLE_REQUEST_NAME.response.body.$.id}} will be sent instead.

The reference syntax of a request variable is a bit more complex than other kinds of custom variables.


### Request Variable Reference Syntax

The request variable reference syntax follows

```text
{{REQUEST_NAME.(response|request).(body|headers).(*|JSONPath|XPath|Header Name)}}`
```

You have two reference part choices of the response or request: body and headers.

For body part, you can use JSONPath and XPath to extract specific property or attribute.


### Special case for cookies

The response cookies can be referenced by
```text
{{REQUEST_NAME.response.cookies.CookieName.(value|domain|flag|path|secure|expires)}}`
```

```http
# @name REQUEST_GH
GET https://github.com HTTP/1.1

###

POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "logged_into_gh": "{{REQUEST_GH.response.cookies.logged_in.value}}"
}
```


> tip
> If you don't want Kulala to create a cookie jar for a specific request, you can add the meta-tag @no-cookie-jar to the request.
>```http
># @no-cookie-jar
>GET https://github.com HTTP/1.1
>```

### Example request variable
if a JSON response returns body {"id": "mock"}, you can set the JSONPath part to $.id to reference the id.
For headers part, you can specify the header name to extract the header value.
The header name is case-sensitive for response part, and all lower-cased for request part.
If the JSONPath or XPath of body, or Header Name of headers can't be resolved, the plain text of variable reference will be sent instead.
And in this case, diagnostic information will be displayed to help you to inspect this.
Below is a sample of request variable definitions and references in an http file.

```http
# @name REQUEST_ONE
POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "token": "foobar"
}

###

# @name REQUEST_TWO
POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "token": "{{REQUEST_ONE.response.body.$.json.token}}"
}

###

POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "date_header": "{{REQUEST_TWO.response.headers['Date']}}"
}
```


---


## Dynamically setting environment variables based on response JSON

You can set environment variables based on the response JSON of a HTTP request.
Create a file with the .http extension and write your HTTP requests in it.


### With built-in parser

If the response is a uncomplicated JSON object, you can set environment variables using the request variables feature.

```http
# Setting the environment variables to be used in the next request.
# @name REQUEST_ONE
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "username": "{{USERNAME}}",
  "password": "{{PASSWORD}}",
  "token": "foobar"
}

###

POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json
Authorization: Bearer {{REQUEST_ONE.response.body.$.json.token}}

{
  "success": true,
  "username": "{{REQUEST_ONE.response.body.$.json.username}}"
}
```


### With external command

If the response is a complex JSON object, you can use the @env-stdin-cmd directive to set environment variables using an external command (e.g., jq).
JSON Web Tokens (JWT) are a common example where the response JSON is complex.
In this example jq is used to extract the ctx string from a JWT token.

```http

# Setting the environment variables to be used in the next request.
# Any external command can be used to set the environment variables.
# The command should output the environment variable as string.
# @env-stdin-cmd JWT_CONTEXT jq -r '.json.token | gsub("-";"+") | gsub("_";"/") | split(".") | .[1] | @base64d | fromjson | .ctx'
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

###

POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "success": true,
  "context": "{{JWT_CONTEXT}}"
}

```


---


## Dynamically setting environment variables based on headers
You can set environment variables based on the headers of a HTTP request.
Create a file with the .http extension and write your HTTP requests in it.


### Example dynamic variables

The headers of the first request can be obtained and used in the second request.
In this example, the Content-Type and Date headers are received in the first request.

```http
# @name REQUEST_ONE
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "type": "very-simple"
}

###

POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "success": true,
  "previous_request_header_content_type": "{{REQUEST_ONE.response.headers['Content-Type']}}",
  "previous_request_header_date": "{{REQUEST_ONE.response.headers.Date}}"
}
```


---


## File to variable

You can use the @file-to-variable directive to read the content of a file and assign it to a variable.
Create a file with the .http extension and write your JSON request in it.
Then, use the @file-to-variable directive to specify the variable name that you want to use in the request.
The second argument is the path to the file.

```http
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json
# @file-to-variable TEST_INCLUDE ./test-include.json

{
  "test-include": {{TEST_INCLUDE}}
}
```

The TEST_INCLUDE variable will be replaced with the content of the test-include.json file.

**test-include.json**
```json
{
  "foo": "bar",
  "baz": {
    "qux": "quux"
  }
}
```


---


## Redirect the response

You can redirect the response to a file.


### Don't overwrite file

By using the >> operator followed by the file name, the response will be saved to the file.
If the file already exists, a warning will be displayed, and the file won't be overwritten.
To overwrite the file, use the >>! operator.

```http
POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "name": "Kulala"
}

>> kulala.json
```


### Overwrite file

To overwrite the file, use the >>! operator.

```http
POST https://httpbin.org/post HTTP/1.1
Accept: application/json
Content-Type: application/json

{
  "name": "Kulala"
}

>>! kulala.json
```


---


## GraphQL

You can use the @graphql directive to send GraphQL requests.
Create a file with the .http extension and write your GraphQL requests in it.


### With variables

```http
POST https://swapi-graphql.netlify.app/.netlify/functions/index HTTP/1.1
Accept: application/json
X-REQUEST-TYPE: GraphQL

query Person($id: ID) {
  person(personID: $id) {
    name
  }
}

{ "id": 1 }
```

### Without variables

```http
POST https://swapi-graphql.netlify.app/.netlify/functions/index HTTP/1.1
Accept: application/json
X-REQUEST-TYPE: GraphQL

query Query {
  allFilms {
    films {
      title
      director
      releaseDate
      speciesConnection {
        species {
          name
          classification
          homeworld {
            name
          }
        }
      }
    }
  }
}
```


---


## Magic Variables

There is a predefined set of magic variables that you can use in your HTTP requests.
They all start with a $ sign.

A Unique User Identifier (UUID) is a 128-bit number used to identify information in computer systems.

- {{$uuid}} - Generates a UUID.
- {{$timestamp}} - Generates a timestamp.
- {{$date}} - Generates a date (yyyy-mm-dd).
- {{$randomInt}} - Generates a random integer (between 0 and 9999999).

To test this feature, create a file with the .http extension and write your HTTP requests in it.

```http
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "uuid": "{{$uuid}}",
  "timestamp": "{{$timestamp}}",
  "date": "{{$date}}",
  "randomInt": "{{$randomInt}}"
}
```


---


## Sending Form Data
You can send form data in Kulala by using the application/x-www-form-urlencoded content type.
Create a file with the .http extension and write your HTTP requests in it.

```http
@name=John
@age=30

POST https://httpbin.org/post HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Accept: application/json

name={{name}}&
age={{age}}
```

### Sending multipart form data
You can send multipart form data in Kulala by using the multipart/form-data content type.

```http
# @file-to-variable LOGO_FILE_VAR ./../../logo.png
POST https://httpbin.org/post HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary{{$timestamp}}

------WebKitFormBoundary{{$timestamp}}
Content-Disposition: form-data; name="logo"; filename="logo.png"
Content-Type: image/jpeg

{{LOGO_FILE_VAR}}

------WebKitFormBoundary{{$timestamp}}
Content-Disposition: form-data; name="x"

0
------WebKitFormBoundary{{$timestamp}}
Content-Disposition: form-data; name="y"

1.4333333333333333
------WebKitFormBoundary{{$timestamp}}
Content-Disposition: form-data; name="w"

514.5666666666667
------WebKitFormBoundary{{$timestamp}}
Content-Disposition: form-data; name="h"

514.5666666666667
------WebKitFormBoundary{{$timestamp}}--
```


---


## Using Environment Variables

You can use environment variables in your HTTP requests.

Create a file with the .http extension and write your HTTP requests in it.

```http
POST https://httpbin.org/post HTTP/1.1
Content-Type: application/json
Accept: application/json

{
  "username": "{{AUTH_USERNAME}}",
  "password": "{{AUTH_PASSWORD}}",
}
```


---


## Using Variables

You can use variables in your HTTP requests.


### Basic document variables

Create a file with the .http extension and write your HTTP requests in it.

```http
@pokemon=pikachu
@pokemon2=bulbasaur

GET https://pokeapi.co/api/v2/pokemon/{{pokemon}} HTTP/1.1
Accept: application/json

###

GET https://pokeapi.co/api/v2/pokemon/{{pokemon2}} HTTP/1.1
Accept: application/json

```

These variables are available in all requests in the file.


### Prompt variables

You can also use prompt variables. These are variables that you can set when you run the request.

```http
# @prompt pokemon
GET https://pokeapi.co/api/v2/pokemon/{{pokemon}} HTTP/1.1
Accept: application/json
```

When you run this request, you will be prompted to enter a value for pokemon.

These variables are available for the current request and all subsequent requests in the file.


