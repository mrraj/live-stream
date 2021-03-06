class SessionsController < ApplicationController

  before_action :current_session, only: [:create, :destroy]
  before_action :set_channel, only: [:create, :destroy]
  skip_before_action :sign_in, only: [:new, :create]

  def new
  end

  def create
    ldap_auth = LdapAuth.new(params[:user][:username], params[:user][:password])

    if (ldap_user = ldap_auth.authenticate?)
      session[:ldap_username] = ldap_user.username
      session[:ldap_user]     = ldap_user
      @sess.update_attributes(username: ldap_user.username)
      RedisServer.instance.push_message(@channel, ldap_user, { online_users: Session.online_users })
      redirect_to channels_path, notice: "User logged in successfully"
    else
      flash.now[:error] = "Ivalid username/password"
      render :new
    end
  end

  def destroy
    session[:ldap_username] = nil
    ldap_user = session.delete(:ldap_user)
    @sess.update_attributes(username: nil)
    RedisServer.instance.push_message(@channel, ldap_user, { online_users: Session.online_users })
    redirect_to new_session_path, notice: "Logged out successfully"
  end

  private
  def current_session
    @sess = Session.find_by_session_id(session.id)
  end

  def set_channel
    @channel = Channel.new name: "online-users"
  end
end
