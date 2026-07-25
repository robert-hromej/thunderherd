# frozen_string_literal: true

# Serves the React (Vite) single-page app shell for every non-API HTML route.
class AppController < ApplicationController
  def index
    render "app/index", layout: false
  end
end
