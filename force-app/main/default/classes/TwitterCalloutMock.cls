@isTest
public class TwitterCalloutMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();

        if (req.getEndpoint().contains('/users/by/username/')) {
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data": {"id": "mockUserId"}}');
            return res;
        }

        if (req.getEndpoint().contains('/users/mockUserId/tweets')) {
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data": [' +
                '{"id": "12345", "text": "Test Tweet 1"},' +
                '{"id": "67890", "text": "Test Tweet 2"}' +
            ']}');
            return res;
        }

        // Mock: Delete tweet
        if (req.getEndpoint().contains('/tweets/')) {
            res.setStatusCode(200);
            res.setBody('{"data": {"deleted": true}}');
            return res;
        }

        res.setStatusCode(404);
        res.setBody('{"error": "Not found"}');
        return res;
    }
}

