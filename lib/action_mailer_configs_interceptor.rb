# frozen_string_literal: true

module ActionMailerConfigsInterceptor
  module_function

  def delivering_email(message)
    if Docuseal.demo?
      message.delivery_method(:test)

      return message
    end

    if Rails.env.production? && Rails.application.config.action_mailer.delivery_method
      message.from = ENV.fetch('SMTP_FROM')

      return message
    end

    email_configs = EncryptedConfig.find_by(key: EncryptedConfig::EMAIL_SMTP_KEY)

    if email_configs
      message.delivery_method(:smtp, build_smtp_configs_hash(email_configs))

      message.from = "#{email_configs.account.name} <#{email_configs.value['from_email']}>"
    else
      message.delivery_method(:test)
    end

    message
  end

  def build_smtp_configs_hash(email_configs)
    value = email_configs.value

    {
      user_name: value['username'],
      password: value['password'],
      address: value['host'],
      port: value['port'],
      domain: value['domain'],
      authentication: value.fetch('authentication', 'plain'),
      enable_starttls_auto: true,
      ssl: value['security'] == 'ssl',
      tls: value['security'] == 'tls' || (value['security'].blank? && value['port'].to_s == '465')
    }.compact_blank
  end
end
