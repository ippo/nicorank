require 'test_helper'

class DayControllerTest < ActionController::TestCase
  test "should get top" do
    get :top
    assert_response :success
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get edit" do
    get :edit
    assert_response :success
  end

  test "should get fix" do
    get :fix
    assert_response :success
  end

  test "should get conf" do
    get :conf
    assert_response :success
  end

  test "should get pass" do
    get :pass
    assert_response :success
  end

  test "should get bbs" do
    get :bbs
    assert_response :success
  end

end
