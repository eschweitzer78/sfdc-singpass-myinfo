import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';

import MYINFO_LOGO from "@salesforce/resourceUrl/MyInfo_Logo";

import USER_NAME_FIELD from "@salesforce/schema/User.Name";
import USER_FIRSTNAME_FIELD from "@salesforce/schema/User.FirstName";
import USER_LASTNAME_FIELD from "@salesforce/schema/User.LastName";
import USER_EMAIL_FIELD from "@salesforce/schema/User.Email";
import USER_PHONE_FIELD from "@salesforce/schema/User.Phone";
import USER_ADDRESS_FIELD from "@salesforce/schema/User.Address";
import USER_STREET_FIELD from "@salesforce/schema/User.Street";
import USER_CITY_FIELD from "@salesforce/schema/User.City";
import USER_POSTALCODE_FIELD from "@salesforce/schema/User.PostalCode";
import USER_COUNTRY_FIELD from "@salesforce/schema/User.Country";
import USER_SMALLPHOTOURL_FIELD from "@salesforce/schema/User.SmallPhotoUrl";

import USER_ID from "@salesforce/user/Id";

import createAuthUrl from "@salesforce/apex/Singpass_MyInfoController.createAuthURL";
import getAccessToken from "@salesforce/apex/Singpass_MyInfoController.getAccessToken";
import getPerson from "@salesforce/apex/Singpass_MyInfoController.getPerson";

export default class Singpass_PersonProfile extends NavigationMixin(LightningElement) {
    @api userId = USER_ID;
    @api isEdit;
    @track isDisabled = true;   
    @track userPhotoUrl;

    myInfoLogoUrl = MYINFO_LOGO;
    fields = [ USER_NAME_FIELD, USER_EMAIL_FIELD, USER_PHONE_FIELD, USER_ADDRESS_FIELD, USER_SMALLPHOTOURL_FIELD ];
    nameField = USER_NAME_FIELD;
    firstNameField = USER_FIRSTNAME_FIELD;
    lastNameField = USER_LASTNAME_FIELD;
    emailField = USER_EMAIL_FIELD;
    phoneField = USER_PHONE_FIELD;
    addressField = USER_ADDRESS_FIELD;
    streetField = USER_STREET_FIELD;
    cityField = USER_CITY_FIELD;
    postalCodeField = USER_POSTALCODE_FIELD;
    countryField = USER_COUNTRY_FIELD;
    photoUrlField = USER_SMALLPHOTOURL_FIELD;

    @track overridePhone;


    handleSave() {
        this.isEdit = true;
    }

    handleRetrieve() {
        let uri = document.URL.split("\?")[0];
        createAuthUrl({ redirectUri: uri })
        .then((authUrl) => {
            window.open(authUrl, "_self");
        })
        .catch((error) => {
            console.log('error ', JSON.stringify(error));
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error',
                messsage: 'Error'
            });

            this.dispatchEvent(event);
        });
    }

    handleEdit() {
        this.isEdit = true;
    }

    handleFieldChanged() {
        this.isDisabled = false;
    }

    handleCancel() {
        this.isEdit = false;
    }

    handleFormLoaded(event) {
        let record = event.detail.records[this.userId];

        if (record) {
            let field = record.fields["SmallPhotoUrl"];
            if (field) {
                this.userPhotoUrl = field.value;
            }
        }
    }

    getUrlParameterByName(name, url) {
        if (!url) {
            url = document.URL;
        }

        console.log(url);

        name = name.replace(/[\[\]]/g, '\\$&');
        let regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);

        if (!results) return null;
        if (!results[2]) return '';

        return decodeURIComponent(results[2].replace(/\+/g, ' '));
    }


    connectedCallback() {
      // you would get a code parameter if the experience cloud page this widget is dropped on 
      // is being redirected to as part of a Singpass MyInfo callback.
        let code = this.getUrlParameterByName("code");

        if (code) {
          // if we're in the callback phase, get the access token based on the authorisation code
          // and eventually the person's details
            this.handleGetAccessToken(code)
        }
    }


    handleGetAccessToken(code) {
        getAccessToken({ code: code })
        .then((gatr) => {
            this.isEdit = true;
            this.handleGetPerson(gatr.token, gatr.sub);
        })
        .catch((error) => {
            console.log('error ', JSON.stringify(error));
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'getAccessToken Error',
                messsage: JSON.stringify(error)
            });

            this.dispatchEvent(event);
        });
    }


    handleGetPerson(token, sub) {
        getPerson({ token: token, sub: sub })
        .then((response) => {
            this.overridePhone = response.mobileno.prefix.value + response.mobileno.areacode.value + response.mobileno.nbr.value;
        })
        .catch((error) => {
            console.log('getPerson error ', JSON.stringify(error));
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'getPerson Error',
                messsage: JSON.stringify(error)
            });

            this.dispatchEvent(event);
        });
    }
}