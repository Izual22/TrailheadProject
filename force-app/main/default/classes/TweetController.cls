public with sharing class TweetController {

    @AuraEnabled(cacheable=true)
    public static List<Tweet__c> getTweetsByContact(Id contactId) {
        return [
            SELECT Id, Name, Tweet_Text__c, Tweet_Date__c, Tweet_ID__c
            FROM Tweet__c
            WHERE Contact__c = :contactId
            ORDER BY Tweet_Date__c DESC
        ];
    }

    @AuraEnabled
    public static String sync(Id contactId) {
        Contact contact = [
            SELECT Twitter_Handle__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        if (String.isBlank(contact.Twitter_Handle__c)) {
            throw new AuraHandledException('No Twitter handle found for this contact.');
        }

        List<TweetWrapper> tweets = fetchTweets(contact.Twitter_Handle__c);

        if (tweets.isEmpty()) {
            return 'No tweets found.';
        }

   		 Map<String, Tweet__c> existingTweetsMap = new Map<String, Tweet__c>();
    	for (Tweet__c t : [
        	SELECT Id, Tweet_ID__c, Tweet_Text__c, Tweet_Date__c
        	FROM Tweet__c
        	WHERE Contact__c = :contact.Id
    	]) {
        	existingTweetsMap.put(t.Tweet_ID__c, t);
    	}

        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>();
        List<Tweet__c> toInsert = new List<Tweet__c>();
        for (TweetWrapper tweet : tweets) {
        Tweet__c existing = existingTweetsMap.get(tweet.id);

	Datetime tweetDate;
	try {
    	tweetDate = Datetime.valueOfGmt(tweet.createdAt.replace('T', ' ').replace('Z', ''));
	} catch (Exception e) {
        LogService.logError(e, 'Could not set date', 'TweetController');
    	throw new AuraHandledException('Invalid tweet date: ' + tweet.createdAt);
	}

        if (existing != null) {
            Boolean needsUpdate = (
                existing.Tweet_Text__c != tweet.text ||
                existing.Tweet_Date__c != tweetDate
            );
            if (needsUpdate) {
                existing.Tweet_Text__c = tweet.text;
                existing.Tweet_Date__c = tweetDate;
                tweetsToUpdate.add(existing);
            }
        } else {
            Tweet__c newTweet = new Tweet__c();
            newTweet.Contact__c = contact.Id;
            newTweet.Tweet_ID__c = tweet.id;
            newTweet.Tweet_Text__c = tweet.text;
            newTweet.Tweet_Date__c = tweetDate;
            toInsert.add(newTweet);
        }
    }
    if (!tweetsToUpdate.isEmpty()) {
        update tweetsToUpdate;
    }
    if (!toInsert.isEmpty()) {
        insert toInsert;
    }
        return toInsert.size() + ' new, ' + tweetsToUpdate.size() + ' updated tweet(s) synced.';
    }

    private static List<TweetWrapper> fetchTweets(String handle) {
            List<Map<String, Object>> rawTweets = new List<Map<String, Object>>();
    		List<Object> raw = (List<Object>) TwitterService.getTweetsByHandle(handle);
    
    		for (Object o : raw) {
        		rawTweets.add((Map<String, Object>) o);
    		}

    		List<TweetWrapper> result = new List<TweetWrapper>();
    		for (Map<String, Object> t : rawTweets) {
        		TweetWrapper tw = new TweetWrapper();
        		tw.id = (String) t.get('id');
        		tw.text = (String) t.get('text');
        		tw.createdAt = (String) t.get('created_at');
        		result.add(tw);
    }

    return result;
    }

    @AuraEnabled
    public static void deleteTweet(Id tweetId) {
        Tweet__c tweet = [
            SELECT Id, Tweet_ID__c
            FROM Tweet__c
            WHERE Tweet_ID__c = :tweetId
            LIMIT 1
        ];

        TwitterService.deleteTweet(tweet.Tweet_ID__c);
        delete tweet;
    }

    public class TweetWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String text;
        @AuraEnabled public String createdAt;
    }
}