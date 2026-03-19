# frozen_string_literal: true

module Api
  module V1
    class PalantirController < ApplicationController
      # POST /api/v1/palantir/send
      def deliver
        message = params[:message].to_s.strip
        if message.blank?
          return render json: { error: "Message is required" }, status: :unprocessable_entity
        end

        PalantirWorker.perform_async({ "message" => message }.to_json)
        render json: { queued: true }, status: :accepted
      end
    end
  end
end
