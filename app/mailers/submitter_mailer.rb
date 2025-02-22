# frozen_string_literal: true

class SubmitterMailer < ApplicationMailer
  DEFAULT_MESSAGE = %(You have been invited to submit the "%<name>s" form:)

  def invitation_email(submitter, message: '')
    @current_account = submitter.submission.template.account
    @submitter = submitter
    @message = message.presence || format(DEFAULT_MESSAGE, name: submitter.submission.template.name)

    @email_config = @current_account.account_configs.find_by(key: AccountConfig::SUBMITTER_INVITATION_EMAIL_KEY)

    subject =
      if @email_config
        ReplaceEmailVariables.call(@email_config.value['subject'], submitter:)
      else
        'You have been invited to submit a form'
      end

    mail(to: @submitter.email,
         subject:,
         reply_to: submitter.submission.created_by_user&.friendly_name)
  end

  def completed_email(submitter, user)
    @current_account = submitter.submission.template.account
    @submitter = submitter
    @user = user

    mail(to: user.email,
         subject: %(#{submitter.email} has completed the "#{submitter.submission.template.name}" form))
  end

  def documents_copy_email(submitter)
    @current_account = submitter.submission.template.account
    @submitter = submitter

    Submissions::EnsureResultGenerated.call(@submitter)

    @documents = Submitters.select_attachments_for_download(submitter)

    @documents.each do |attachment|
      attachments[attachment.filename.to_s] = attachment.download
    end

    mail(to: submitter.email, subject: 'Your copy of documents')
  end
end
