trigger TweetTrigger on Tweet__c (before insert, after delete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        TriggerHandler.handleAfterDelete(Trigger.old);
    }
}