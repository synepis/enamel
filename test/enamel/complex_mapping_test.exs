defmodule Enamel.ComplexMappingTest do
  use ExUnit.Case

  @schedule_xml """
  <Schedule date="2017-11-01" trainId="TRAIN001">

    <Origin>
      <Location stationCode="LDN">London</Location>
      <ScheduleTimes>
        <DepartureTime>10:30:00</DepartureTime>
      </ScheduleTimes>
    </Origin>

    <Stop isPublic="false">
      <Location stationCode="BHM">Birmingham</Location>
      <ScheduleTimes>
        <ArrivalTime>10:50:00</ArrivalTime>
        <DepartureTime>10:55:00</DepartureTime>
      </ScheduleTimes>
    </Stop>

    <Stop isPublic="true">
      <Location stationCode="MAN">Manchester</Location>
      <ScheduleTimes>
        <ArrivalTime>11:42:00</ArrivalTime>
        <DepartureTime>11:47:00</DepartureTime>
      </ScheduleTimes>
    </Stop>

  <Stop>
    <Location stationCode="CAR">Carlisle</Location>
    <ScheduleTimes>
      <ArrivalTime>12:15:00</ArrivalTime>
      <DepartureTime>12:17:00</DepartureTime>
    </ScheduleTimes>
  </Stop>

  <Destination>
    <Location stationCode="EDB">Edingburgh</Location>
    <Platform number="4" />
    <ScheduleTimes>
      <ArrivalTime>13:00:00</ArrivalTime>
    </ScheduleTimes>
  </Destination>

  </Schedule>
  """

  defmodule Model do

    ##  Parsing helpers

    def parse_bool_str("true"), do: true
    def parse_bool_str("false"), do: false

    ## Models

    defmodule Schedule do
      use Enamel.MappingInfo
      defstruct [:date, :train_id, :origin, :stops, :destination]

      def attributes(), do: %{
        'date'        => {:date, &Date.from_iso8601!/1 },
        'trainId'     => :train_id }
      def items(), do: %{
        'Origin'      => { :origin,      Model.Stop },
        'Stop'        => { :stops,       [Model.Stop] },
        'Destination' => { :destination, Model.Stop }}
    end

    defmodule Stop do
      use Enamel.MappingInfo
      defstruct [ {:public, true }, :location, :schedule, :platform ]
      def attributes(), do: %{
        'isPublic'      => { :public,         &Model.parse_bool_str/1 }}
      def items(), do: %{
        'Location'      => { :location,       Model.Location },
        'ScheduleTimes' => { :schedule,       Model.ScheduleTimes },
        'Platform'      => { :platform,       Model.Platform }}

    end

    defmodule Location do
      use Enamel.MappingInfo
      defstruct [ :code, :name ]
      def attributes(), do: %{ 'stationCode' => :code }
      def text(), do: { :name, &Enum.join/1 }
    end

    defmodule ScheduleTimes do
      use Enamel.MappingInfo
      defstruct [ :arrival_time, :departure_time]
      def items(), do: %{
        'ArrivalTime'   => { :_arrival_time, Model.Time },
        'DepartureTime' => { :_departure_time, Model.Time }
      }
      def refine() do
        fn schedule_times ->
          arr = schedule_times._arrival_time
          dep = schedule_times._departure_time

          schedule_times
          |> Map.put(:arrival_time, (if arr, do: arr.time, else: nil))
          |> Map.put(:departure_time, (if dep, do: dep.time, else: nil))
        end
      end
    end

    defmodule Time do
      use Enamel.MappingInfo
      defstruct [:time]
      def text(), do: { :time, fn x -> x |> Enum.join |> Elixir.Time.from_iso8601! end }
    end

    defmodule Platform do
      use Enamel.MappingInfo
      defstruct [:number]
      def attributes(), do: %{ 'number' => :number }
    end
  end

  test "maps sucessfully a complex document" do
    {:ok, xml_mapping, _} = :erlsom.simple_form(@schedule_xml)

    schedule = Enamel.ErlsomMapper.map(xml_mapping, __MODULE__.Model.Schedule)

    assert schedule.date == ~D[2017-11-01]
    assert schedule.train_id == "TRAIN001"

    origin = schedule.origin
    assert origin.location.code == "LDN"
    assert origin.location.name == "London"
    assert origin.schedule.arrival_time == nil
    assert origin.schedule.departure_time == ~T[10:30:00]
    assert origin.public == true

    stop1 = Enum.at(schedule.stops, 0)
    assert stop1.location.code == "BHM"
    assert stop1.location.name == "Birmingham"
    assert stop1.schedule.arrival_time == ~T[10:50:00]
    assert stop1.schedule.departure_time == ~T[10:55:00]
    assert stop1.public == false

    stop2 = Enum.at(schedule.stops, 1)
    assert stop2.location.code == "MAN"
    assert stop2.location.name == "Manchester"
    assert stop2.schedule.arrival_time == ~T[11:42:00]
    assert stop2.schedule.departure_time == ~T[11:47:00]
    assert stop2.public == true

    stop3 = Enum.at(schedule.stops, 2)
    assert stop3.location.code == "CAR"
    assert stop3.location.name == "Carlisle"
    assert stop3.schedule.arrival_time == ~T[12:15:00]
    assert stop3.schedule.departure_time == ~T[12:17:00]
    assert stop3.public == true

    dest = schedule.destination
    assert dest.location.code == "EDB"
    assert dest.location.name == "Edingburgh"
    assert dest.schedule.arrival_time == ~T[13:00:00]
    assert dest.schedule.departure_time == nil
    assert dest.public == true

  end

end
