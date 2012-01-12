require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase
   #
   # In this test class, Configuration["param1"] cannot be used.
   # Internaly, Configuration.[] method calls "convert_type".  So instead of testing Configuration.[],
   # Configuration#convert_type will be tested.
   #
   test "retrieve string data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"12345_abcde", :raw_value_type=>"string")
      assert_equal "12345_abcde", conf.convert_type
   end

   test "retrieve integer data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"12345", :raw_value_type=>"integer")
      assert_equal 12345, conf.convert_type
   end

   test "retrieve boolean [true] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"true", :raw_value_type=>"boolean")
      assert_equal true, conf.convert_type
   end

   test "retrieve boolean [t is true] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"t", :raw_value_type=>"boolean")
      assert_equal true, conf.convert_type
   end

   test "retrieve boolean [TRUE is true] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"TRUE", :raw_value_type=>"boolean")
      assert_equal true, conf.convert_type
   end

   test "retrieve boolean [false] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"false", :raw_value_type=>"boolean")
      assert_equal false, conf.convert_type
   end

   test "retrieve boolean [strange value is false] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"asliurekajdsflka", :raw_value_type=>"boolean")
      assert_equal false, conf.convert_type
   end

   test "retrieve boolean [nil is false] data correctly" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>nil, :raw_value_type=>"boolean")
      assert_equal false, conf.convert_type
   end

   test "range string" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"delete", :raw_value_type=>"string[delete,export_and_delete]")
      conf.convert_type
      assert_equal "string[delete,export_and_delete]", conf.raw_value_type
      assert_equal "string", conf.value_type
      assert_equal "delete", conf.value
      assert_equal ["delete", "export_and_delete"], conf.valid_data_list
   end

   test "range integer" do
      conf = Configuration.new(:variable=>"param1", :raw_value=>"12345", :raw_value_type=>"integer[1..99999]")
      conf.convert_type
      assert_equal "integer[1..99999]", conf.raw_value_type
      assert_equal "integer", conf.value_type
      assert_equal 12345, conf.value
      assert_equal 1..99999, conf.valid_data_list
   end
end
