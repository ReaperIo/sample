my_app:

GET:
- /status
- /status/{:id}      <- returned json with parameters: message {error/success}, results: sql data by id ( if exist )
- /status/{:id}.html <- returned html table with sql data

PUT:
- /status/{:domain} <- add domain to database ( if not exists & valid ) with data from domain

DELETE:
- /status/{:id} <- remove domain by id ( if exist )


:id - only numbers

:domain - with/without schema & with/without port. only http/https


tests:
t/create.t <- test for create any record
t/show.t   <- test for show all & record by id

#--------------------------------------------------------

Sample:

$ curl --request "PUT" http://localhost:3000/status/http://asdsdklfksnkjsg.com
return data: {"message":"error","result":"incorrect url: http:\/\/asdsdklfksnkjsg.com"}

$ curl --request "PUT" http://localhost:3000/status/google.com
return data: {"message":"error","result":"url: google.com already exist"}

$ curl --request "GET" http://localhost:3000/status/1
{"message":"success","results":{"date_upd":"2022-12-10 18:28:29.426177","headers_field":null,"http_status":null,"url":"google.com"}}

#--------------------------------------------------------

lib:

- sheduler:
использовал `mcuadros/ofelia`, так как неизвестно, какая OS на сервере
да и ставить `cron` - лишняя нагрузка и лишние файлы

- DBIx::Custom
обёртка для DBI, для очистки кода от захламления. 
использует те же драйвера, что и DBI.
если надо - можно и на оригинале, просто удобнее.

#--------------------------------------------------------

возврат данных по умолчанию сделал в виде json ( обычно такие вещи забирают микросервисы, по крайней мере у меня ).
но как пример - есть в виде html.
