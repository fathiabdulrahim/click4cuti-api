class WarningLetterMailer < ApplicationMailer
  def issued(warning_letter)
    @letter     = warning_letter
    @user       = warning_letter.user
    @leave_type = warning_letter.leave_type
    @company    = warning_letter.company

    mail(
      to:      @user.email,
      subject: "Warning Letter Issued — Excessive #{@leave_type.name}"
    ) do |format|
      format.text do
        render plain: <<~TEXT
          Dear #{@user.full_name},

          This is to inform you that a warning letter has been issued against your record.

          Reason: #{@letter.reason}
          Date: #{@letter.issued_date}

          Please acknowledge this warning letter in the HR portal.

          Regards,
          #{@company.name} HR Department
        TEXT
      end
    end
  end
end
