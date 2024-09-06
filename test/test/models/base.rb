require "test_helper"

# Common tests for all models.
module BaseModelTests
  TITLE_FIELDS = [:name, :login]

  def self.included(base)
    base.setup do
      @model ||= self.class.name.match(/(.*)Test$/)[1].constantize
      @title_field ||= TITLE_FIELDS.select { |f| f.to_s.in?(@model.column_names) }[0]

      Rails.application.load_seed
    end
  end

  def test_record_exists_from_fixture
    assert(@model.exists?)
  end

  def test_can_create_record
    if @title_field
      @model.create!(@title_field => "test_create")
      assert(@model.where(@title_field => "test_create").exists?)
    else
      raise StandardError, "#{@model} doesn't contain any of these fields: #{TITLE_FIELDS}"
    end
  end

  def test_can_update_record
    if @title_field
      t = @model.create!(@title_field => "test_update")
      t.update!(@title_field => "test_updated")
      assert(@model.where(@title_field => "test_updated").exists?)
    else
      raise StandardError, "#{@model} doesn't contain any of these fields: #{TITLE_FIELDS}"
    end
  end

  def test_can_destroy_record
    record = @model.first
    record.destroy!
    assert_not(@model.exists?(record.id))
  end
end
