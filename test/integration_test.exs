defmodule Ecto.DateRange.IntegrationTest do
  use Ecto.DateRange.DataCase

  alias TestApp.Table

  test "it can cast new data" do
    %{first: first, last: last} = range = range()

    assert Table.changeset(%Table{}, %{name: "name", range: range}) == %Ecto.Changeset{
             changes: %{
               range: %Postgrex.Range{
                 lower: first,
                 upper: last,
                 lower_inclusive: true,
                 upper_inclusive: true
               },
               name: "name"
             },
             required: [:name, :range],
             data: %TestApp.Table{id: nil, name: nil, range: nil},
             params: %{"range" => Date.range(first, last), "name" => "name"},
             types: %{range: Ecto.DateRange, id: :id, name: :string},
             valid?: true
           }
  end

  test "it can cast against existing data" do
    assert %Ecto.Changeset{valid?: true} =
             cs = Table.changeset(%Table{}, %{name: "name", range: range()})

    assert %Table{} = t = Ecto.Changeset.apply_changes(cs)

    assert Table.changeset(t, %{range: Date.range(~D[2020-01-01], ~D[2020-12-31])}) ==
             %Ecto.Changeset{
               changes: %{
                 range: %Postgrex.Range{
                   lower: ~D[2020-01-01],
                   upper: ~D[2020-12-31],
                   lower_inclusive: true,
                   upper_inclusive: true
                 }
               },
               data: %TestApp.Table{
                 id: nil,
                 name: "name",
                 range: %Postgrex.Range{
                   lower: ~D[1989-09-22],
                   upper: ~D[2021-03-01],
                   lower_inclusive: true,
                   upper_inclusive: true
                 }
               },
               params: %{"range" => Date.range(~D[2020-01-01], ~D[2020-12-31])},
               required: [:name, :range],
               types: %{range: Ecto.DateRange, id: :id, name: :string},
               valid?: true
             }
  end

  test "can round trip Date.Range through the database" do
    %{first: first, last: last} = range = range()

    assert %Table{id: id} = TestApp.Repo.insert!(%Table{name: "a", range: range})

    assert %TestApp.Table{
             range: %Postgrex.Range{
               lower: ^first,
               upper: ^last,
               lower_inclusive: true,
               upper_inclusive: true
             },
             id: ^id,
             name: "a"
           } = TestApp.Repo.get!(Table, id)
  end

  test "can round trip Postgrex.Range through the database with exclusive lower bound" do
    range = %Postgrex.Range{
      lower: ~D[1989-09-22],
      upper: ~D[2021-03-01],
      lower_inclusive: false,
      upper_inclusive: true
    }

    assert %Table{id: id} = TestApp.Repo.insert!(%Table{name: "a", range: range})

    assert %TestApp.Table{
             range: %Postgrex.Range{
               lower: ~D[1989-09-23],
               lower_inclusive: true,
               upper: ~D[2021-03-01],
               upper_inclusive: true
             },
             id: ^id,
             name: "a"
           } = TestApp.Repo.get!(Table, id)
  end

  test "can round trip Postgrex.Range through the database with exclusive upper bound" do
    range = %Postgrex.Range{
      lower: ~D[1989-09-22],
      upper: ~D[2021-03-01],
      lower_inclusive: true,
      upper_inclusive: false
    }

    assert %Table{id: id} = TestApp.Repo.insert!(%Table{name: "a", range: range})

    assert %TestApp.Table{
             range: %Postgrex.Range{
               lower: ~D[1989-09-22],
               lower_inclusive: true,
               upper: ~D[2021-02-28],
               upper_inclusive: true
             },
             id: ^id,
             name: "a"
           } = TestApp.Repo.get!(Table, id)
  end

  describe "int4range" do
    test "can round trip a range through the database" do
      range = %Postgrex.Range{
        lower: 1,
        upper: 3,
        lower_inclusive: true,
        upper_inclusive: true
      }

      assert %Table{id: id} = TestApp.Repo.insert!(%Table{name: "a", int4range: range})
      assert %TestApp.Table{id: ^id, int4range: ^range, name: "a"} = TestApp.Repo.get!(Table, id)
    end

    test "returns an error if integers outside the int4 range are given" do
      range = %Postgrex.Range{
        lower: -2_147_483_649,
        upper: 2_147_483_648,
        lower_inclusive: true,
        upper_inclusive: true
      }

      assert {:error, error} = TestApp.Context.create_table(%{name: "a", int4range: range})
      assert [int4range: {"is invalid", [type: Ecto.Int4range, validation: :cast]}] = error.errors
    end
  end

  def range(_context \\ %{}) do
    Date.range(~D[1989-09-22], ~D[2021-03-01])
  end
end
