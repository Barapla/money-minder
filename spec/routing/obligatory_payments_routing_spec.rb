require "rails_helper"

RSpec.describe ObligatoryPaymentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/obligatory_payments").to route_to("obligatory_payments#index")
    end

    it "routes to #new" do
      expect(get: "/obligatory_payments/new").to route_to("obligatory_payments#new")
    end

    it "routes to #show" do
      expect(get: "/obligatory_payments/1").to route_to("obligatory_payments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/obligatory_payments/1/edit").to route_to("obligatory_payments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/obligatory_payments").to route_to("obligatory_payments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/obligatory_payments/1").to route_to("obligatory_payments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/obligatory_payments/1").to route_to("obligatory_payments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/obligatory_payments/1").to route_to("obligatory_payments#destroy", id: "1")
    end
  end
end
