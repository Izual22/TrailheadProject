public with sharing class CreateTweetsJob implements Queueable, Database.AllowsCallouts {
    Private List<Id> tweetIds;
    public CreateTweetsJob(List<Tweet__c> tweets) {
        this.tweetIds = new List<Id>();
        for (Tweet__c t : tweets) {
            this.tweetIds.add(t.Id);
        }
    }
    public void execute(QueueableContext context){
        List<Tweet__c> tweets = [
            SELECT Id, Tweet_Text__c, Tweet_Date__c, Contact__c, Contact__r.Twitter_Handle__c
            FROM Tweet__c
            WHERE Id IN :tweetIds
        ];
        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>();
        for(Tweet__c t :tweets){
            try{
                Map<String, Object> tweetData = TwitterService.createTweet(t.Tweet_Text__c);
                String tweetId = (String) tweetData.get('id');
                String createdAt = (String) tweetData.get('created_at');
                if (tweetId != null) {
                    t.Tweet_ID__c = tweetId;
                    tweetsToUpdate.add(t);
                }
                if (createdAt != null) {
                    t.Tweet_Date__c = DateTime.valueOfGmt(createdAt);
                }
                tweetsToUpdate.add(t);
            }catch(Exception ex){
                LogService.logError(ex, 'Failed to create tweet and update Tweet__c', 'CreateTweetsJob');
            }
        }
        if (!tweetsToUpdate.isEmpty()) {
            update tweetsToUpdate;
        }
    }
}