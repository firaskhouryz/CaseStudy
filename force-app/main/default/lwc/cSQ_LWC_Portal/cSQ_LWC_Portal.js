import { LightningElement } from 'lwc';
import submitApplication from '@salesforce/apex/CSQ_APEX_ApplicationFormController.submit';

const REQUIRED_FIELDS = ['companyName', 'firstName', 'lastName', 'email', 'phone'];

/**
 * Application form component.
 *
 * Collects UI input, performs lightweight client-side validation, and submits the
 * normalized payload to Apex.
 */
export default class ApplicationForm extends LightningElement {

    form = this.createEmptyForm();
    isLoading = false;
    successMessage = '';
    errorMessage = '';

    /** Disables the submit button while an Apex request is in-flight. */
    get isSubmitDisabled() {
        return this.isLoading;
    }

    /**
     * Handles input changes from lightning-input fields.
     * @param {Event} event Lightning input change event.
     */
    handleChange(event) {
        const fieldName = event?.target?.name;
        if (!fieldName) return;
        const value = event.detail?.value;
        this.form = {
            ...this.form,
            [fieldName]: value
        };
    }

    /** Resets all form fields back to their initial values. */
    handleReset() {
        this.form = this.createEmptyForm();
    }

    /**
     * Validates and submits the form to Apex.
     * Sets a user-friendly success or error message based on the response.
     */
    handleSubmit() {
        this.clearMessages();
        if (!this.validateForm()) {
            this.setError('Please populate all the required fields.');
            return;
        }
        this.isLoading = true;
        const payload = this.buildPayload();

        submitApplication({ submission: payload })
            .then((result) => {
                if (result?.ok) {
                    const createdType = result?.created?.sObjectType;
                    const message = createdType
                        ? ('Application submitted. ' + createdType + ' created successfully.')
                        : 'Thanks — your application has been received.';
                    this.setSuccess(message);
                    this.handleReset();
                    return;
                }

                this.setError(result?.userMessage || 'Submission failed.');
            })
            .catch((error) => {
                const message = error?.body?.message || error?.message || 'Submission failed. Please try again.';
                this.setError(message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /** Clears both success and error messages. */
    clearMessages() {
        this.successMessage = '';
        this.errorMessage = '';
    }

    /**
     * Sets the success message and clears the error state.
     * @param {string} message Success message.
     */
    setSuccess(message) {
        this.successMessage = message || '';
        this.errorMessage = '';
    }

    /**
     * Sets the error message and clears the success state.
     * @param {string} message Error message.
     */
    setError(message) {
        this.errorMessage = message || 'Unknown error';
        this.successMessage = '';
    }

    /**
     * Creates a new empty form state.
     * @returns {object} Empty form object.
     */
    createEmptyForm() {
        return {
            companyName: '',
            federalTaxId: '',
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            annualRevenue: null
        };
    }

    /**
     * Validates required fields on the client.
     * @returns {boolean} True when required values are present.
     */
    validateForm() {
        return REQUIRED_FIELDS.every((field) => {
            return this.toTrimmedString(this.form[field]) !== null;
        });
    }

    /**
     * Builds the payload expected by CSQ_WRP_ApplicationSubmission.
     * @returns {object} Submission payload with nested organization/applicant/financials sections.
     */
    buildPayload() {
        const trimmedCompanyName = this.toTrimmedString(this.form.companyName);
        const trimmedTaxId = this.toTrimmedString(this.form.federalTaxId);
        const trimmedFirstName = this.toTrimmedString(this.form.firstName);
        const trimmedLastName = this.toTrimmedString(this.form.lastName);
        const trimmedEmail = this.toTrimmedString(this.form.email);
        const trimmedPhone = this.toTrimmedString(this.form.phone);
        const annualRevenue = this.toNumber(this.form.annualRevenue);

        return {
            organization: {
                legalName: trimmedCompanyName,
                taxId: trimmedTaxId
            },
            applicant: {
                givenName: trimmedFirstName,
                familyName: trimmedLastName,
                emailAddress: trimmedEmail,
                phoneNumber: trimmedPhone
            },
            financials: {
                annualRevenue: annualRevenue
            }
        };
    }

    /**
     * Converts a value to a trimmed string, returning null for blank values.
     * @param {*} value Any input value.
     * @returns {string|null} Trimmed string or null.
     */
    toTrimmedString(value) {
        if (value === null || value === undefined) return null;
        const str = String(value).trim();
        return str === '' ? null : str;
    }

    /**
     * Converts a value to a number, returning null for invalid/blank values.
     * @param {*} value Any input value.
     * @returns {number|null} Parsed number or null.
     */
    toNumber(value) {
        if (value === null || value === undefined || value === '') return null;
        const num = Number(value);
        return num || num === 0 ? num : null;
    }
}