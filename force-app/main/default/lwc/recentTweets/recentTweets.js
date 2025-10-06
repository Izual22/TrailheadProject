import { LightningElement,api,wire } from 'lwc';
import getTweetsByContact from '@salesforce/apex/TweetController.getTweetsByContact';
import sync from '@salesforce/apex/TweetController.sync';
import deleteTweet from '@salesforce/apex/TweetController.deleteTweet';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns =[
    {label:'Tweet Text',fieldName:'Tweet_Text__c'},
    {label:'Tweet Date',fieldName:'Tweet_Date__c'},
    {label: 'Tweet Id', fieldName:'Tweet_ID__c'},
        {
        type: 'button',
        typeAttributes: {
            label: 'Delete',
            name: 'delete',
            title: 'Delete',
            variant: 'destructive',
        iconName: 'utility:delete'       
     }
    }
]

export default class RecentTweets extends LightningElement {
    
visibleTweets = [];
currentPage = 1;
pageSize = 5;
totalPages = 1;
    @api recordId;
        error;
        tweets;
        columns = columns;
        wiredResult;
        @wire(getTweetsByContact,{contactId:'$recordId'})
        wiredTweets(result){
            this.wiredResult = result;
            if(result.data){
                this.tweets = result.data;
                this.totalPages=Math.ceil(this.tweets.length/this.pageSize);
                this.setPage(1);
                this.error = undefined;
            }else if(result.error){
                this.error = result.error.body.message;
                this.tweets = undefined;
                this.visibleTweets=[];
            }
        }
        syncing = false;
        handleSync(){
            this.syncing = true;
            sync({contactId:this.recordId}).then(message=>{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Synced',
                        message:message,
                        variant:'success'
                    })
                );
                this.syncing=false;
            }).catch(error=>{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title:'Error',
                        message:error.body.message,
                        variant:'error'
                    })
                );
                this.syncing=false;
            })
        }
        handleRowAction(event){
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            if(actionName === 'delete'){
                deleteTweet({ tweetId: row.Id })
    .then(() => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Tweet deleted',
                variant: 'success'
            })
        );
        return refreshApex(this.wiredResult);
    })
    .catch(error => {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Failed to delete tweet',
                variant: 'error'
            })
        );
    });
            }
        }
        setPage(page){
            this.currentPage=page;
            const start = (page-1)*this.pageSize;
            const end = start+this.pageSize;
            this.visibleTweets=this.tweets.slice(start,end);
        }
        handleNext(){
            if(this.currentPage<this.totalPages){
                this.setPage(this.currentPage+1);
            }
        }
        handlePrevious(){
            if(this.currentPage>1){
                this.setPage(this.currentPage-1);
            }
        }
        get disablePrevious(){
            return this.currentPage===1;
        }
        get disableNext(){
            return this.currentPage===this.totalPages;
        }
    }
