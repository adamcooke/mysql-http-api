# MySQL HTTP API

This HTTP server provides an HTTP-interface direct to a MySQL database. The main
purpose for a server like this would be to allow clients to talk to a MySQL
database using HTTP when native MySQL is unavailable.

## Running/Installing

It's easy to run the HTTP server for this. Just clone the repo, install the
dependencies and run the web server through bundler.

```
git clone https://github.com/adamcooke/mysql-api
cd mysql-api
bundle
bundle exec rackup
```

Bare in mind that the server that you install this on will need to be able to
access the databases which you connecting to.

## Using the API

Once the server is running you can send requests to it containing server
credentials and the queries you want to execute. You should send the queries to
the `/query` endpoint.

The body of your request should be JSON-formatted and the content type for the
request must be `application/json`.

An example request looks like this:

```javascript
{
  "host":"localhost",
  "username":"root",
  "password":"supersecretpassword",
  "database":"mydatabase",
  "queries":[
    {
      "name":"explain",
      "query":"EXPLAIN users;"
    },
    {
      "name":"total_count",
      "query":"SELECT COUNT(id) AS count FROM users;"
    },
    {
      "name":"records",
      "query":"SELECT * FROM users LIMIT 10;"
    },
    {
      "name":"prepared_query",
      "query":"SELECT * FROM users WHERE username = ? AND first_name = ?;"
      "values":["adamcooke", "Adam"]
    }
  ]
}
```

You can see from here we'll providing connection details plus an array of
queries which we want to be executed with this database. You also provide a
`name` which will be returned to you along with the result so you can easily
map a query you sent to a result that you've received.

You will always receive a JSON response which will be a hash containing the
results of all the queries which you have sent. Each query will contain details
of the rows & columns which were returned.

```javascript
{
  "explain":{
    "status":"ok",
    "size":3,
    "cols":["Field", "Type", "Null", "Key", "Default", "Extra"],
    "rows":[
      ["id", "int(11)", "NO", "PRI", null, "auto_increment"],
      ["username", "varchar(60)", "YES", "", null, ""],
      ["enabled", "tinyint(1)", "YES", "", null, ""]
    ]
  }
}
```

* `status` - this specifies that the query was successful
* `size` - the number of rows returned
* `cols` - the names of the columns which have been returned
* `rows` - every row which was returned as an array of values

### Connection & Query Errors

There are two types of errors which you are likely to receive. The first is a
connection error which means the credentials you have provided are not correct.
This will be returned as a `403 Forbidden` HTTP status with a body like this:

```javascript
{
  "code": "connection-error",
  "message": "Unknown MySQL server host 'myserver.blah.com' (0)"
}
```

The code will always be `connection-error` and the message will be returned
straight from the MySQL server. It may also be an access denied or unknown
database message.

The other type of error you may find is an error in one of the queries which you
submit. If a query generates an error the `status` attribute will be `error` and
a `message` attribute will contain details. All other queries will be executed
as normal even if one of the queries submitted with it fails.

```javascript
{
  "status": "error",
  "message": "Table 'smi.potatos' doesn't exist"
}
```
