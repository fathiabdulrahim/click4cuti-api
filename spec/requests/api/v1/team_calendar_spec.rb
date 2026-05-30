require "rails_helper"

RSpec.describe "Api::V1::TeamCalendar", type: :request do
  let!(:company)       { create(:company) }
  let!(:other_company) { create(:company) }
  let!(:policy)        { create(:leave_policy, company: company) }
  let!(:policy_b)      { create(:leave_policy, company: other_company) }
  let!(:leave_type)    { create(:leave_type, leave_policy: policy, name: "Annual Leave") }
  let!(:leave_type_b)  { create(:leave_type, leave_policy: policy_b, name: "Annual Leave B") }
  let!(:employee)      { create(:user, :employee, company: company) }
  let!(:colleague)     { create(:user, :employee, company: company) }
  let!(:outsider)      { create(:user, :employee, company: other_company) }

  let(:today) { Date.current }

  let!(:leave_today) do
    create(:leave_application, :approved, user: colleague, leave_type: leave_type,
           start_date: today, end_date: today, total_days: 1.0)
  end

  let!(:leave_upcoming) do
    create(:leave_application, :approved, user: colleague, leave_type: leave_type,
           start_date: today + 5.days, end_date: today + 7.days, total_days: 3.0)
  end

  let!(:leave_other_company) do
    create(:leave_application, :approved, user: outsider, leave_type: leave_type_b,
           start_date: today, end_date: today, total_days: 1.0)
  end

  describe "GET /api/v1/team_calendar" do
    it_behaves_like "requires authentication", :get, "/api/v1/team_calendar"

    context "as authenticated employee" do
      subject { get "/api/v1/team_calendar", headers: auth_headers_for_user(employee) }

      it "returns 200" do
        subject
        expect(response).to have_http_status(:ok)
      end

      it "returns today_summary and upcoming_entries keys" do
        subject
        body = response.parsed_body
        expect(body).to include("today_summary", "upcoming_entries")
      end

      it "includes employees_out_count for today" do
        subject
        expect(response.parsed_body.dig("today_summary", "employees_out_count")).to eq(1)
      end

      it "includes total_team_size in today_summary" do
        subject
        expect(response.parsed_body.dig("today_summary", "total_team_size")).to be_a(Integer)
      end

      it "lists colleague name in employees_out" do
        subject
        names = response.parsed_body.dig("today_summary", "employees_out").map { |e| e["name"] }
        expect(names).to include(colleague.full_name)
      end

      it "does not leak other company employees into today_summary" do
        subject
        names = response.parsed_body.dig("today_summary", "employees_out").map { |e| e["name"] }
        expect(names).not_to include(outsider.full_name)
      end

      it "includes upcoming entries for the default 30-day window" do
        subject
        user_names = response.parsed_body["upcoming_entries"].map { |e| e["user_name"] }
        expect(user_names).to include(colleague.full_name)
      end

      it "returns leave_type, start_date, end_date, total_days on each entry" do
        subject
        entry = response.parsed_body["upcoming_entries"].find { |e| e["user_name"] == colleague.full_name }
        expect(entry).to include("leave_type", "start_date", "end_date", "total_days")
      end

      it "does not include other company leaves in upcoming_entries" do
        subject
        user_names = response.parsed_body["upcoming_entries"].map { |e| e["user_name"] }
        expect(user_names).not_to include(outsider.full_name)
      end
    end

    context "with custom from/to params" do
      it "filters upcoming entries to the requested range" do
        from = (today + 5.days).iso8601
        to   = (today + 7.days).iso8601
        get "/api/v1/team_calendar", params: { from: from, to: to },
            headers: auth_headers_for_user(employee)
        expect(response).to have_http_status(:ok)
        user_names = response.parsed_body["upcoming_entries"].map { |e| e["user_name"] }
        expect(user_names).to include(colleague.full_name)
      end

      it "excludes leaves outside the requested range" do
        from = (today + 20.days).iso8601
        to   = (today + 25.days).iso8601
        get "/api/v1/team_calendar", params: { from: from, to: to },
            headers: auth_headers_for_user(employee)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["upcoming_entries"]).to be_empty
      end
    end
  end
end