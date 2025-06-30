# frozen_string_literal: true

# BudgetsController handles the display of budgets.
class BudgetsController < ApplicationController
  def index
    @budgets = Budget.all
  end

  def new
    @budget = Budget.new
  end

  def create
  end
end
