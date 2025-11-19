require 'rails_helper'

RSpec.describe "patient_joins/compare", type: :view do
  before do
    @patient_record_1 = create(:patient,
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com",
      administrative_gender: :male)

    @patient_record_2 = create(:patient,
      first_name: "Jon",
      last_name: "Doe",
      email: "jon@example.com",
      administrative_gender: :male)

    @patient_join = PatientJoin.new(
      from_patient_record: @patient_record_1,
      to_patient_record: @patient_record_2,
      qualifier: :has_same_identity_as
    )

    assign(:patient_record_1, @patient_record_1)
    assign(:patient_record_2, @patient_record_2)
    assign(:patient_join, @patient_join)
  end

  it "renders the comparison form" do
    render

    assert_select "form[action=?][method=?]", patient_joins_path, "post" do
      assert_select "input[name=?][value=?]", "patient_join[from_patient_record_id]", @patient_record_1.id.to_s
      assert_select "input[name=?][value=?]", "patient_join[to_patient_record_id]", @patient_record_2.id.to_s
      assert_select "input[name=?][value=?]", "patient_join[qualifier]", "has_same_identity_as"
      assert_select "textarea[name=?]", "patient_join[notes]"
      assert_select "input[type=submit][value=?]", "Link These Patient Records"
    end
  end

  it "displays both patient records side by side" do
    render

    # Patient 1
    expect(rendered).to match(/Patient Record 1/)
    expect(rendered).to include(@patient_record_1.first_name)
    expect(rendered).to include(@patient_record_1.email)

    # Patient 2
    expect(rendered).to match(/Patient Record 2/)
    expect(rendered).to include(@patient_record_2.first_name)
    expect(rendered).to include(@patient_record_2.email)
  end

  it "renders patient record details partial for both patients" do # rubocop:disable RSpec/MultipleExpectations
    render

    # Both patient UUIDs should be displayed
    expect(rendered).to include(@patient_record_1.uuid)
    expect(rendered).to include(@patient_record_2.uuid)
  end
end
