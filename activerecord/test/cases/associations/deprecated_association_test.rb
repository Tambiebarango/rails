# frozen_string_literal: true

require "cases/helper"


class DeprecatedAssociationTest < ActiveRecord::TestCase
  class ClassRoom < ActiveRecord::Base
    self.table_name = "class_rooms"

    has_many :tables, association_deprecated: true
  end

  class Table < ActiveRecord::Base
    self.table_name = "tables"

    belongs_to :class_room
    has_one :chair, association_deprecated: true
  end

  class Chair < ActiveRecord::Base
    self.table_name = "chairs"

    belongs_to :table, association_deprecated: true
  end

  class Teacher < ActiveRecord::Base
    self.table_name = "teachers"

    belongs_to :teachable, polymorphic: true, association_deprecated: true
  end

  class Student < ActiveRecord::Base
    self.table_name = "students"

    has_many :teachers, as: :teachable, association_deprecated: true
  end

  class Pupil < ActiveRecord::Base
    self.table_name = "pupils"

    has_many :teachers, as: :teachable, association_deprecated: true
  end

  def setup
    @connection = ActiveRecord::Base.lease_connection
    @connection.create_table :class_rooms, force: true
    @connection.create_table :tables, force: true do |t|
      t.belongs_to :class_room
    end
    @connection.create_table :chairs, force: true do |t|
      t.belongs_to :table
    end
    @connection.create_table :teachers, force: true do |t|
      t.belongs_to :teachable, polymorphic: true
    end
    @connection.create_table :students, force: true
    @connection.create_table :pupils, force: true
  end

  def teardown
    @connection.drop_table :class_rooms, if_exists: true
    @connection.drop_table :tables, if_exists: true
    @connection.drop_table :chairs, if_exists: true
    @connection.drop_table :teachers, if_exists: true
    @connection.drop_table :students, if_exists: true
    @connection.drop_table :pupils, if_exists: true
  end

  def test_issues_deprecation_warning_for_has_one_accessors
    methods_to_test = [:chair, :build_chair, :create_chair, :reload_chair, :reset_chair]
    table = Table.create!
    expected_message = "The association chair on DeprecatedAssociationTest::Table has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        table.public_send(meth)
      end
    end
  end

  def test_issues_deprecation_warning_for_has_one_simple_query_methods
    methods_to_test = [:joins, :includes, :preload, :eager_load]

    expected_message = "The association chair on DeprecatedAssociationTest::Table has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        Table.public_send(meth, :chair)
      end
    end
  end

  def test_issues_deprecation_warning_for_nested_query_methods
    # in this example, Table => Chair is deprecated, but is nested in a set of preloaded/included/eager loaded/joined associations

    methods_to_test = [:joins, :includes, :preload, :eager_load]

    methods_to_test.each do |meth|
      warnings = []

      ActiveRecord.deprecator.stub :warn, ->(msg) { warnings << msg } do
        ClassRoom.public_send(meth, { tables: :chair })
      end

      assert_includes(warnings, "The association tables on DeprecatedAssociationTest::ClassRoom has been deprecated")
      assert_includes(warnings, "The association chair on DeprecatedAssociationTest::Table has been deprecated")
    end
  end

  def test_issues_deprecation_warning_for_has_many_reader_methods
    methods_to_test = [:tables, :table_ids]

    class_room = ClassRoom.create!
    expected_message = "The association tables on DeprecatedAssociationTest::ClassRoom has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        class_room.public_send(meth)
      end
    end
  end

  def test_issues_deprecation_warning_for_has_many_writer_method
    class_room = ClassRoom.create!
    expected_message = "The association tables on DeprecatedAssociationTest::ClassRoom has been deprecated"

    ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
      class_room.tables = [Table.create!]
    end
  end

  def test_issues_deprecation_warning_for_belongs_to_accessors
    methods_to_test = [:table, :build_table, :create_table, :reload_table, :reset_table, :table_changed?, :table_previously_changed?]
    chair = Chair.create!
    expected_message = "The association table on DeprecatedAssociationTest::Chair has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        chair.public_send(meth)
      end
    end
  end

  def test_issues_deprecation_warning_for_belongs_to_query_methods
    methods_to_test = [:joins, :includes, :preload, :eager_load]

    expected_message = "The association table on DeprecatedAssociationTest::Chair has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        Chair.public_send(meth, :table)
      end
    end
  end

  def test_issues_deprecation_warning_for_polymorphic_belongs_to_accessors
    methods_to_test = [:teachable, :reload_teachable, :reset_teachable, :teachable_changed?, :teachable_previously_changed?]
    teacher = Teacher.create!(teachable: Student.create!)
    expected_message = "The association teachable on DeprecatedAssociationTest::Teacher has been deprecated"

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { assert_match expected_message, msg } do
        teacher.public_send(meth)
      end
    end
  end

  def test_does_not_issue_deprecation_warning_for_polymorphic_query_methods
    methods_to_test = [:joins, :includes, :preload, :eager_load]
    deprecation_warning_issued = false

    methods_to_test.each do |meth|
      ActiveRecord.deprecator.stub :warn, ->(msg) { deprecation_warning_issued = true } do
        Teacher.public_send(meth, :teachable)
        Student.public_send(meth, :teachers)
        Pupils.public_send(meth, :teachers)
      end
    end

    refute deprecation_warning_issued
  end
end