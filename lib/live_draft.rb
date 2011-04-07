module LiveDraft
  module Base
    def has_draft?
      !send(:"#{draft_attr_name}?") && draft != nil
    end

    def save_draft(attrs = {})
      return update_attributes(attrs) if send(:"#{draft_attr_name}?")
      
      draft = find_draft attrs
      draft.attributes = attributes.merge(attrs)
      draft.send(:"#{draft_attr_name}=", true)
      draft.save
    end

    def draft
      return self if send(:"#{draft_attr_name}?")
      my_class.where(published_id_attr => id).first
    end

    def published
      my_class.where(id: send(published_id_attr)).first || my_class.new
    end

    def publish(attrs = {})
      return save unless send(:"#{draft_attr_name}?")

      record = published
      record.attributes = attributes.merge(attrs)
      record.send(:"#{draft_attr_name}=", false)

      if record.save
        send(:"#{published_id_attr}=", record.id)
        destroy
      else
        copy_errors(record)
        false
      end
    end

  private
    def my_class
      self.class
    end

    def live_draft_config
      my_class.live_draft_config
    end

    def draft_attr_name
      live_draft_config[:attr] || :draft
    end

    def published_id_attr
      live_draft_config[:published_id] || :published_id
    end

    def draft_id_attr
      live_draft_config[:draft_id] || :"#{draft_attr_name}_id"
    end

    def set_draft
      send(:"#{draft_attr_name}=", false) unless send(:"#{draft_attr_name}?")
      true
    end

    def find_draft(attrs)
      if new_record?
        my_class.find_by_id(attrs[draft_id_attr]) || self
      else
        my_class.send(:"find_or_create_by_#{published_id_attr}", id)
      end
    end

    def copy_errors(record)
      record.errors.each { |field, message| errors.add(field, message) }
    end
  end

  module ActiveRecordAdapter
    def has_live_draft(options = {})
      include LiveDraft::Base
      class_attribute :live_draft_config
      self.live_draft_config = options
      before_save :set_draft
    end
  end
end

module ActiveRecord
  class Base
    extend LiveDraft::ActiveRecordAdapter
  end
end
