defmodule WippliBackend.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias WippliBackend.Accounts.User


  schema "users" do
    field :phone, :string
    field :telegram_id, :string
    field :nickname, :string
    #has_many :zones, WippliBackend.Wippli.Zone, foreign_key: :created_zone
    has_many :zones, WippliBackend.Wippli.Zone, foreign_key: :created_by
    has_many :requests, WippliBackend.Wippli.Request, foreign_key: :requested_by
    has_one :participants, WippliBackend.Wippli.Participant
    timestamps()
  end


  @required_fields ~w(nickname)a
  @optional_fields ~w(telegram_id phone)a
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:phone, name: :phone_not_unique )
  end
end
