public class DeleteTweetsJob implements Queueable, Database.AllowsCallouts {
    private List<String> tweetIds;
    public DeleteTweetsJob(List<String> tweetIds) {
        this.tweetIds = tweetIds;
    }

    public void execute(QueueableContext context) {

        List<Tweet__c> tweets = [
            SELECT Id, Tweet_ID__c
            FROM Tweet__c
            WHERE Id IN :tweetIds
        ];
        for (Tweet__c t : tweets) {
            try {
                TwitterService.deleteTweet(t.Tweet_ID__c);
            } catch (Exception ex) {
                LogService.logError(ex, 'Failed to delete tweet in DeleteTweetsJob', 'TwitterService');
            }
        }
    }
}