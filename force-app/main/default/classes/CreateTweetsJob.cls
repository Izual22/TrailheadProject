public with sharing class CreateTweetsJob implements Queueable, Database.AllowsCallouts {
    List<Tweet__c>  tweets;
    public CreateTweetsJob(List<Tweet__c> tweetsToUpdate) {
        this.tweets = new List<Tweet__c>();
        for (Tweet__c t : tweetsToUpdate) {
            this.tweets.add(t);
        }
    }
    public void execute(QueueableContext context){
        List<Tweet__c> tweetsToUpdate = new List<Tweet__c>();
        for(Tweet__c t :tweets){
            try{
                TwitterService.createTweet(t.Tweet_Text__c,t);
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