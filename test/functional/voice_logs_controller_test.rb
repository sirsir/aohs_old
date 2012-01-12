require 'test_helper'

class VoiceLogsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:voice_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create voice_log" do
    assert_difference('VoiceLog.count') do
      post :create, :voice_log => { }
    end

    assert_redirected_to voice_log_path(assigns(:voice_log))
  end

  test "should show voice_log" do
    get :show, :id => voice_logs(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => voice_logs(:one).id
    assert_response :success
  end

  test "should update voice_log" do
    put :update, :id => voice_logs(:one).id, :voice_log => { }
    assert_redirected_to voice_log_path(assigns(:voice_log))
  end

  test "should destroy voice_log" do
    assert_difference('VoiceLog.count', -1) do
      delete :destroy, :id => voice_logs(:one).id
    end

    assert_redirected_to voice_logs_path
  end
end
