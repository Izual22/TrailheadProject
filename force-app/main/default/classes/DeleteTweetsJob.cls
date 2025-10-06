public class DeleteTweetsJob implements Queueable, Database.AllowsCallouts {
    private List<String> tweetIds;

    public DeleteTweetsJob(List<String> tweetIds) {
        this.tweetIds = tweetIds;
    }

    public void execute(QueueableContext context) {
        for (String id : tweetIds) {
            try {
                TwitterService.deleteTweet(id);
            } catch (Exception ex) {
                LogService.logError(ex, 'Failed to delete tweet in DeleteTweetsJob', 'TwitterService');
            }
        }
    }
}