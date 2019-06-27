class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    # 查询数据库有无用户且密码正确与否！
    if user && user.authenticate(params[:session][:password])
      # 判断登入用户是否激活！
      if user.activated?
        log_in user
        params[:session][:remember_me] == '1' ? remember(user) : forget(user)
        redirect_back_or user
      else
        message  = "Account not activated. "
        message += "Check your email for the activation link."
        flash[:warning] = message
        redirect_to root_url
      end
    else
      # 账户或密码错误！
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    log_out  if logged_in?   #调用log_out辅助方法
    redirect_to root_url
  end
end
