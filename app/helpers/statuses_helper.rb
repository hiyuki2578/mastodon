# frozen_string_literal: true

module StatusesHelper
  EMBEDDED_CONTROLLER = 'statuses'
  EMBEDDED_ACTION = 'embed'

  def display_name(account, **options)
    if options[:custom_emojify]
      Formatter.instance.format_display_name(account, options)
    else
      account.display_name.presence || account.username
    end
  end

  def account_action_button(account)
    if user_signed_in?
      if account.id == current_user.account_id
        link_to settings_profile_url, class: 'button logo-button' do
          safe_join([svg_logo, t('settings.edit_profile')])
        end
      elsif current_account.following?(account) || current_account.requested?(account)
        link_to account_unfollow_path(account), class: 'button logo-button button--destructive', data: { method: :post } do
          safe_join([svg_logo, t('accounts.unfollow')])
        end
      elsif !(account.memorial? || account.moved?)
        link_to account_follow_path(account), class: "button logo-button#{account.blocking?(current_account) ? ' disabled' : ''}", data: { method: :post } do
          safe_join([svg_logo, t('accounts.follow')])
        end
      end
    elsif !(account.memorial? || account.moved?)
      link_to account_remote_follow_path(account), class: 'button logo-button modal-button', target: '_new' do
        safe_join([svg_logo, t('accounts.follow')])
      end
    end
  end

  def minimal_account_action_button(account)
    if user_signed_in?
      return if account.id == current_user.account_id

      if current_account.following?(account) || current_account.requested?(account)
        link_to account_unfollow_path(account), class: 'icon-button active', data: { method: :post }, title: t('accounts.unfollow') do
          fa_icon('user-times fw')
        end
      elsif !(account.memorial? || account.moved?)
        link_to account_follow_path(account), class: "icon-button#{account.blocking?(current_account) ? ' disabled' : ''}", data: { method: :post }, title: t('accounts.follow') do
          fa_icon('user-plus fw')
        end
      end
    elsif !(account.memorial? || account.moved?)
      link_to account_remote_follow_path(account), class: 'icon-button modal-button', target: '_new', title: t('accounts.follow') do
        fa_icon('user-plus fw')
      end
    end
  end

  def svg_logo
    content_tag(:svg, tag(:use, 'xlink:href' => '#mastodon-svg-logo'), 'viewBox' => '0 0 216.4144 232.00976')
  end

  def svg_logo_full
    content_tag(:svg, tag(:use, 'xlink:href' => '#mastodon-svg-logo-full'), 'viewBox' => '0 0 713.35878 175.8678')
  end

  def account_badge(account, all: false)
    roles = []

    roles.push content_tag(:div, t('accounts.roles.bot'), class: 'account-role bot') if account.bot?
    roles.push content_tag(:div, t('accounts.roles.cat'), class: 'account-role cat') if account.cat?

    if (Setting.show_staff_badge && account.user_staff?) || all
      if all && !account.user_staff?
        roles.push content_tag(:div, t('admin.accounts.roles.user'), class: 'account-role')
      elsif account.user_admin?
        roles.push content_tag(:div, t('accounts.roles.admin'), class: 'account-role admin')
      elsif account.user_moderator?
        roles.push content_tag(:div, t('accounts.roles.moderator'), class: 'account-role moderator')
      end
    end
    content_tag(:div, safe_join(roles, ' '), class: 'roles') unless roles.empty?
  end

  def link_to_more(url)
    link_to t('statuses.show_more'), url, class: 'load-more load-gap'
  end

  def link_to_newer(url)
    link_to t('statuses.show_newer'), url, class: 'load-more load-gap'
  end

  def link_to_older(url)
    link_to t('statuses.show_older'), url, class: 'load-more load-gap'
  end

  def nothing_here(extra_classes = '')
    content_tag(:div, class: "nothing-here #{extra_classes}") do
      t('accounts.nothing_here')
    end
  end

  def media_summary(status)
    attachments = { image: 0, video: 0, audio: 0 }

    status.media_attachments.each do |media|
      if media.video?
        attachments[:video] += 1
      elsif media.audio?
        attachments[:audio] += 1
      else
        attachments[:image] += 1
      end
    end

    text = attachments.to_a.reject { |_, value| value.zero? }.map { |key, value| I18n.t("statuses.attached.#{key}", count: value) }.join(' · ')

    return if text.blank?

    I18n.t('statuses.attached.description', attached: text)
  end

  def status_text_summary(status)
    return if status.spoiler_text.blank?

    I18n.t('statuses.content_warning', warning: status.spoiler_text)
  end

  def poll_summary(status)
    return unless status.preloadable_poll

    status.preloadable_poll.options.map { |o| "[ ] #{o}" }.join("\n")
  end

  def status_description(status)
    components = [[media_summary(status), status_text_summary(status)].reject(&:blank?).join(' · ')]

    if status.spoiler_text.blank?
      components << status.text
      components << poll_summary(status)
    end

    components.reject(&:blank?).join("\n\n")
  end

  def stream_link_target
    embedded_view? ? '_blank' : nil
  end

  def style_classes(status, is_predecessor, is_successor, include_threads)
    classes = ['entry']
    classes << 'entry-predecessor' if is_predecessor
    classes << 'entry-reblog' if status.reblog?
    classes << 'entry-successor' if is_successor
    classes << 'entry-center' if include_threads
    classes.join(' ')
  end

  def microformats_classes(status, is_direct_parent, is_direct_child)
    classes = []
    classes << 'p-in-reply-to' if is_direct_parent
    classes << 'p-repost-of' if status.reblog? && is_direct_parent
    classes << 'p-comment' if is_direct_child
    classes.join(' ')
  end

  def microformats_h_class(status, is_predecessor, is_successor, include_threads)
    if is_predecessor || status.reblog? || is_successor
      'h-cite'
    elsif include_threads
      ''
    else
      'h-entry'
    end
  end

  def fa_visibility_icon(status)
    case status.visibility
    when 'public'
      fa_icon 'globe fw'
    when 'unlisted'
      fa_icon 'unlock fw'
    when 'private'
      fa_icon 'lock fw'
    when 'direct'
      fa_icon 'envelope fw'
    end
  end

  def sensitized?(status, account)
    if !account.nil? && account.id == status.account_id
      status.sensitive
    else
      status.account.sensitized? || status.sensitive
    end
  end

  private

  def simplified_text(text)
    text.dup.tap do |new_text|
      URI.extract(new_text).each do |url|
        new_text.gsub!(url, '')
      end

      new_text.gsub!(Account::MENTION_RE, '')
      new_text.gsub!(Tag::HASHTAG_RE, '')
      new_text.gsub!(/\s+/, '')
    end
  end

  def embedded_view?
    params[:controller] == EMBEDDED_CONTROLLER && params[:action] == EMBEDDED_ACTION
  end

  def render_video_component(status, **options)
    video = status.media_attachments.first

    meta = video.file.meta || {}

    component_params = {
      sensitive: sensitized?(status, current_account),
      src: full_asset_url(video.file.url(:original)),
      preview: full_asset_url(video.thumbnail.present? ? video.thumbnail.url : video.file.url(:small)),
      alt: video.description,
      blurhash: video.blurhash,
      frameRate: meta.dig('original', 'frame_rate'),
      inline: true,
      media: [
        ActiveModelSerializers::SerializableResource.new(video, serializer: REST::MediaAttachmentSerializer),
      ].as_json,
    }.merge(**options)

    react_component :video, component_params do
      render partial: 'statuses/attachment_list', locals: { attachments: status.media_attachments }
    end
  end

  def render_audio_component(status, **options)
    audio = status.media_attachments.first

    meta = audio.file.meta || {}

    component_params = {
      src: full_asset_url(audio.file.url(:original)),
      poster: full_asset_url(audio.thumbnail.present? ? audio.thumbnail.url : status.account.avatar_static_url),
      alt: audio.description,
      backgroundColor: meta.dig('colors', 'background'),
      foregroundColor: meta.dig('colors', 'foreground'),
      accentColor: meta.dig('colors', 'accent'),
      duration: meta.dig('original', 'duration'),
    }.merge(**options)

    react_component :audio, component_params do
      render partial: 'statuses/attachment_list', locals: { attachments: status.media_attachments }
    end
  end

  def render_media_gallery_component(status, **options)
    component_params = {
      sensitive: sensitized?(status, current_account),
      autoplay: prefers_autoplay?,
      media: status.media_attachments.map { |a| ActiveModelSerializers::SerializableResource.new(a, serializer: REST::MediaAttachmentSerializer).as_json },
    }.merge(**options)

    react_component :media_gallery, component_params do
      render partial: 'statuses/attachment_list', locals: { attachments: status.media_attachments }
    end
  end

  def render_card_component(status, **options)
    component_params = {
      sensitive: sensitized?(status, current_account),
      maxDescription: 160,
      card: ActiveModelSerializers::SerializableResource.new(status.preview_card, serializer: REST::PreviewCardSerializer).as_json,
    }.merge(**options)

    react_component :card, component_params
  end

  def render_poll_component(status, **options)
    component_params = {
      disabled: true,
      poll: ActiveModelSerializers::SerializableResource.new(status.preloadable_poll, serializer: REST::PollSerializer, scope: current_user, scope_name: :current_user).as_json,
    }.merge(**options)

    react_component :poll, component_params do
      render partial: 'statuses/poll', locals: { status: status, poll: status.preloadable_poll, autoplay: prefers_autoplay? }
    end
  end

  def prefers_autoplay?
    ActiveModel::Type::Boolean.new.cast(params[:autoplay]) || current_user&.setting_auto_play_gif
  end
end
