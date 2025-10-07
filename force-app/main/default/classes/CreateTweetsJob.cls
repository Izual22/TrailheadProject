public with sharing class CreateTweetsJob implements Queueable, Database.AllowsCallouts {
    List<Tweet__c>  tweets;
    public CreateTweetsJob(List<Tweet__c> tweetsToUpdate) {
        this.tweets = new List<Tweet__c>();
    for (Tweet__c t : tweetsToUpdate) {
        Tweet__c temp = new Tweet__c(
            Id = t.Id,
            Tweet_Text__c = t.Tweet_Text__c
        );
        this.tweets.add(temp);
    }
    }
    public void execute(QueueableContext context){
        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>();
        for(Tweet__c t :tweets){
            try{
                String tweetId = TwitterService.createTweet(t.Tweet_Text__c);
                DateTime createdAt = DateTime.now();
                if (tweetId != null) {
                    t.Tweet_ID__c = tweetId;
                }
                if (createdAt != null) {
                    t.Tweet_Date__c = createdAt;
                }
                if (t.Id != null) {
                tweetsToUpdate.add(t);
                }
            }catch(Exception ex){
                LogService.logError(ex, 'Failed to create tweet and update Tweet__c', 'CreateTweetsJob');
            }
        }
        if (!tweetsToUpdate.isEmpty()) {
            update tweetsToUpdate;
        }
    }
}