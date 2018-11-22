# frozen_string_literal: true

class ActivityPub::Adapter < ActiveModelSerializers::Adapter::Base
  CONTEXT = {
    '@context': [
      'https://www.w3.org/ns/activitystreams',
      'https://w3id.org/security/v1',

      {
        'manuallyApprovesFollowers' => 'as:manuallyApprovesFollowers',
        'sensitive'                 => 'as:sensitive',
        'movedTo'                   => { '@id' => 'as:movedTo', '@type' => '@id' },
        'Hashtag'                   => 'as:Hashtag',
        'ostatus'                   => 'http://ostatus.org#',
        'atomUri'                   => 'ostatus:atomUri',
        'inReplyToAtomUri'          => 'ostatus:inReplyToAtomUri',
        'conversation'              => 'ostatus:conversation',
        'toot'                      => 'http://joinmastodon.org/ns#',
        'Emoji'                     => 'toot:Emoji',
        'focalPoint'                => { '@container' => '@list', '@id' => 'toot:focalPoint' },
        'featured'                  => { '@id' => 'toot:featured', '@type' => '@id' },
        'schema'                    => 'http://schema.org#',
        'PropertyValue'             => 'schema:PropertyValue',
        'value'                     => 'schema:value',
        'isCat'                     => 'as:isCat',
      },
    ],
  }.freeze

  def self.default_key_transform
    :camel_lower
  end

  def self.transform_key_casing!(value, _options)
    ActivityPub::CaseTransform.camel_lower(value)
  end

  def serializable_hash(options = nil)
    options         = serialization_options(options)
    serialized_hash = serializer.serializable_hash(options)
    serialized_hash = self.class.transform_key_casing!(serialized_hash, instance_options)

    { '@context' => serialized_context }.merge(serialized_hash)
  end

  private

  def serialized_context
    context_array = []

    serializer_options = serializer.send(:instance_options) || {}
    named_contexts     = [:activitystreams] + serializer._named_contexts.keys + serializer_options.fetch(:named_contexts, {}).keys
    context_extensions = serializer._context_extensions.keys + serializer_options.fetch(:context_extensions, {}).keys

    named_contexts.each do |key|
      context_array << NAMED_CONTEXT_MAP[key]
    end

    extensions = context_extensions.each_with_object({}) do |key, h|
      h.merge!(CONTEXT_EXTENSION_MAP[key])
    end

    context_array << extensions unless extensions.empty?

    if context_array.size == 1
      context_array.first
    else
      context_array
    end
  end
end
