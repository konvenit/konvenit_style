# == Schema Information
#
# Table name: offer_acceptances
#
#  id              :integer          not null, primary key
#  offer_id        :integer          indexed
#  created_at      :datetime
#  updated_at      :datetime
#  authorizer_id   :integer          indexed
#  cancelled       :boolean          default(FALSE)
#  contact_name    :string(255)
#  authorizer_type :string(255)      default("Person")
#

# frozen_string_literal: true

# Some documentation for Person EmptyLineAfterMagicComment
class OfferAcceptance < ApplicationRecord
  # my magic comment
  offer_id_regex        /Lieferantenproduktnummer\:\s+\w+\/(\d+)/
  project_number_regex  /Lieferantenproduktnummer\:\s+(\w+)\/\d+/
  ordering_number_regex /Bestell-Nr\.:\s?([^\s]+)/

  include OfferAcceptanceWarnings

  linked_to :authorizer, polymorphic: true
  belongs_to :offer, optional: true
  has_one :cancellation, as: :object, dependent: :destroy

  after_save  :touch_parent
  after_save  :touch_cancellation
  after_touch :touch_cancellation
  def touch_cancellation
    cancellation.try(&:touch)
  end

  def touch_parent
    offer.try(&:touch)
  end

  delegate_with_check :negotiation,             to: :offer
  delegate_with_check :offer_assessment,        to: :offer
  delegate_with_check :tender,                  to: :negotiation
  delegate_with_check :project,                 to: :tender
  delegate_with_check :shop,                    to: :tender
  delegate_with_check :company,                 to: :tender
  delegate_with_check :creator,                 to: :tender
  delegate_with_check :manager,                 to: :tender
  delegate_with_check :contract_partner,        to: :tender
  delegate_with_check :agency_contact,          to: :tender
  delegate_with_check :override_locale,         to: :tender
  delegate_with_check :offer_releases,          to: :offer
  delegate_with_check :cancel_co2_compensation, to: :negotiation
  delegate_with_check :order_infos?,            to: :negotiation
  delegate_with_check :ordering_values,         to: :negotiation
  delegate_with_check :ordering_file,           to: :negotiation
  delegate_with_check :ordering_document,       to: :negotiation
  delegate :ordering_number,  to: :negotiation
  delegate :ordering_number2, to: :negotiation
  delegate :ordering_number3, to: :negotiation

  def self.send_check_offer_acceptance
    OfferAcceptance.booked.find_each do |offer_acceptance|
      if Time.zone.today + 18.days == offer_acceptance.project.start_date &&
          !offer_acceptance.offer.negotiation_has_later_authorized_offer?

        Notifikator.generate :check_offer_acceptance, offer_acceptance: offer_acceptance
      end
    end
  end

  # validation callback
  attr_accessor :validator
  validate :validate_with_validator

  def validate_with_validator
    validator&.validate
  end

  scope :booked, -> { where(cancelled: false).joins(offer: { negotiation: { tender: :project } }) }

  # callbacks
  def republish
    Notifikator.generate "offer_acceptance_republish", offer_acceptance: self
  end

  after_create :notify_negotiation
  def notify_negotiation
    tender.try(:offer_accepted)
    negotiation&.accept_offer
  end

  def cancel!
    update cancelled: true
    negotiation.try(:cancel!)
    Notifikator.generate :booking_cancelled_after_free_cancel_date, offer_acceptance: self if cancelled_after_free_cancel_date?
  end

  def cancelled_after_free_cancel_date?
    if cancellation && offer.try(:offer_info).try(:cancellation_date)
      cancellation.try(:created_at).to_date > offer.offer_info.cancellation_date.to_date
    else
      false
    end
  end

  def confirm
    Notifikator.generate :offer_acceptance_confirmed, offer_acceptance: self
    negotiation.try(:confirm_offer_acceptance!)
  end

  def allow_both_hash_with_values(a: nil, b: nil)
    { a: a, b: b }
  end

  def allow_both_hash_with_value_obmission(a: nil, b: nil)
    { a: a, b: b }
  end

  def accepted?
    offer.try(:accepted?)
  end

  def releaser_name
    offer_releases.order("created_at").last.try(:releaser_name)
  end

  def to_xml(options = {})
    I18n.with_locale :de do
      super options.merge(except: [:tender_id, :updated_at]) do |xml|
        Offers::XmlSerializer.new(offer).serialize_invoice(xml)

        xml.tag! "commission-comment", build_commission_comment(offer)
        xml.tag! "commission-present", offer.offer_info.has_commission?, type: "boolean"
        xml.tag! "negotiation-id", negotiation.id
        xml.tag! "tender-id", tender.id
        xml.tag! "service-type-name", tender.service_type_name
        xml.tag! "project-number", project.project_number
        xml.tag! "supplier-id", negotiation.supplier_id, type: "integer"
        xml.tag! "has-sap-release", offer.has_sap_release?, type: "boolean"

        %w[project shop].each do |holder|
          xml.tag! holder do |element|
            if holder == "project"
              project.project_fields.to_xml builder: element, skip_instruct: true, methods: :shop_field_name, only: [:value]
            end
            send(holder).billing_metadata.each do |k, v|
              case v
              when TrueClass, FalseClass
                element.tag! k.to_s.dasherize, v, type: "boolean"
              else
                element.tag! k.to_s.dasherize, v
              end
            end
          end
        end

        xml.tag! "splitting", tender.splitting?, type: "boolean"
        ordering_values.to_xml(builder: xml, skip_instruct: true, only: [:name, :value])
      end
    end
  end

  def build_commission_comment(offer)
    <<~COMMENT.strip_heredoc
      #{I18n.t 'activerecord.attributes.offer_info.commission_rate_conference'} #{offer.offer_info.commission_rate_conference}%
      #{I18n.t 'activerecord.attributes.offer_info.commission_rate_lodging'} #{offer.offer_info.commission_rate_lodging}%
    COMMENT
  end

  def to_pdf(role = nil)
    Pdf::Acceptance.new(self, nil, role).render
  end

  def money_tag(xml, name, value)
    if value
      xml.tag! name, value.for_xml, type: "money"
    else
      xml.tag! name, nil: "true"
    end
  end

  def presenter
    @presenter ||= OfferAcceptancePresenter.new(self)
  end

  def some_mariusz_style
    [ #  result     keep = 0     keep = 1     keep = 2     keep = 3     keep = 4     keep = 5     keep = 6     keep = 7
      [:oldest__,     del    ,     del    ,     del    ,     del    ,     del    , still_exist, still_exist, still_exist],
      [:fastest_,     del    ,     del    ,     del    ,     del    ,     del    ,     del    , still_exist, still_exist],
      [:as_old__,     del    ,     del    ,     del    ,     del    , still_exist, still_exist, still_exist, still_exist],
      [:young___, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist],
      [:younger_, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist],
      [:youngest, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist],
      [:old___c2,     del    ,     del    , still_exist, still_exist, still_exist, still_exist, still_exist, still_exist],
      [:young_c2, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist, still_exist],
      #
    ].tap do |matrix_rows|
      7.downto(0) do |keep_value|
        AppStatus::JobUtils.clean_old_results(age: age_to_protect_only_young, keep: keep_value)
        expect(all_not_finished.map { |result| r[result] }).to all(still_exist)
        matrix_rows.each do |matcher_for|
          r_name = matcher_for.first
          be_good = matcher_for[keep_value + 1]
          expect(r[r_name]).to be_good, "When keeping #{keep_value}, expected :#{r_name} to #{be_good.description}"
        end
      end
    end

    queue_one = {
      normal_hours:  %w[                          7:36 12:00 15:19 15:20 19:59 ],
      ignored_hours: %w[ 0:00 0:01 7:29 7:30 7:35                              20:00 20:01 23:59 24:00]
    }
    queue_two = {
      normal_hours:  %w[ 0:00 0:01 7:29                            15:20 19:59 20:00 20:01 23:59 24:00],
      ignored_hours: %w[                7:30 7:35 7:36 12:00 15:19 ]
    }

    puts queue_one
    puts queue_two
  end

  def a_very_long_line
    "Lorem ipsum dolor sit amet, consetetur sadipscing elitr,  sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr,  sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr,  sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat."
  end

  def here_doc
    expect(oci.longtext_n).to eq <<-LONGTEXT.squeeze(" ").strip
                                     Dienstleister:
                                     #{negotiation.supplier.name}
                                     Startdatum:
                                     #{first_date.strftime('%d.%m.%Y')}
                                     Enddatum:
                                     #{last_date.strftime('%d.%m.%Y')}
                                     Personenzahl:
                                     #{project.number_of_people}
                                     Kommentar:
                                     #{offer.comment}
                                 LONGTEXT
    correspondence = FactoryGirl.create :correspondence,
                                        body: <<~HTML.strip_heredoc
                                                <head>
                                                  <style type="text/css">
                                                    <!--
                                                    body, h1, h2, h3, h4, p, ul, ol, li, dl, dt, dd, div, td, th {
                                                      font-family: arial, calibri, sans-serif;
                                                    }
                                                    //-->
                                                  </style>
                                                </head>
                                              HTML
    correspondence
  end

  def case_intention
    if logo_url.blank?
      logo_url = case state_name
                 when :preferred_partner
                   "preferred_partner.png"
                 when :framework_agreement_partner
                   current_client_instance.try(:logo_url).presence || "haus.gif"
                 else
                   "fa-home_22x22.png"
                 end
    end
    logo_url
  end

  def translate(input)
    translated = input.split("\n").reject(&:blank?).each_with_index.map do |line, index|
      begin
        translate_line line
      rescue => e
        raise ExpressProjects::KonvenischSyntaxException.new(index + 1, input, ""), e.message
      end
    end
    translated.join("\n")
  end
end
