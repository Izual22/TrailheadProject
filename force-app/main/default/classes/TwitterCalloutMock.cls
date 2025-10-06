@isTest
global class TwitterCalloutMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(201);
        res.setBody('{"data": {"id": "1234567890", "created_at": "2023-10-05T12:34:56.000Z"}}');
        return res;
    }
    }
