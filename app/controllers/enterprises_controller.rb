#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++
class EnterprisesController < ApplicationController
  include EnterpriseTrialHelper

  layout 'admin'
  menu_item :enterprise

  helper_method :gon

  before_action :augur_content_security_policy
  before_action :chargebee_content_security_policy
  before_action :youtube_content_security_policy
  before_action :require_admin
  before_action :check_user_limit, only: [:show]

  def show
    @current_token = EnterpriseToken.current
    @token = @current_token || EnterpriseToken.new

    if @current_token.blank?
      initialize_gon
    end
  end

  def create
    @token = EnterpriseToken.current || EnterpriseToken.new
    @token.encoded_token = params[:enterprise_token][:encoded_token]
    @token.save
  end

  def destroy
    token = EnterpriseToken.current
    if token
      token.destroy
      flash[:notice] = t(:notice_successful_delete)
      redirect_to action: :show
    else
      render_404
    end
  end

  def create_trial_key
    @trial_key = params[:trial_key]
    Token::EnterpriseTrialToken.create(user_id: current_user.id, value: @trial_key)
  end

  def initialize_gon
    @trial_key = Token::EnterpriseTrialToken.find_by!(user_id: current_user.id)
    if @trial_key
      gon.ee_trial_key = {
        value: @trial_key.value
      }
    end
  end

  private

  def default_breadcrumb
    t(:label_enterprise)
  end

  def show_local_breadcrumb
    true
  end

  def check_user_limit
    if OpenProject::Enterprise.user_limit_reached?
      flash.now[:warning] = I18n.t(
        "warning_user_limit_reached_instructions",
        current: OpenProject::Enterprise.active_user_count,
        max: OpenProject::Enterprise.user_limit
      )
    end
  end
end
