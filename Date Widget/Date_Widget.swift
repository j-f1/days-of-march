//
//  Date_Widget.swift
//  Date Widget
//
//  Created by Jed Fox on 9/8/20.
//

import WidgetKit
import SwiftUI
import Intents

let gregorian = { () -> Calendar in
  var cal = Calendar(identifier: .gregorian)
  cal.locale = .current
  return cal
}()

let midnight = { gregorian.startOfDay(for: Date()) }

struct COVID: Decodable {
    let death: Int
}

let deaths = try? JSONDecoder().decode([COVID].self, from: Data(contentsOf: URL(string: "https://api.covidtracking.com/v1/us/current.json")!)).first?.death


struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
      SimpleEntry(date: midnight(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
      print(midnight())
        let entry = SimpleEntry(date: midnight(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
      print(midnight())
      let timeline = Timeline(entries: [SimpleEntry(date: midnight(), configuration: configuration)], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

let marchFirst = DateComponents(calendar: gregorian, year: 2020, month: 3, day: 1).date!
let formatter = { () -> NumberFormatter in
  var formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter
}()

func format(_ rate: Double) -> String {
    let integer = Int(rate.rounded(.down))
    let fraction = rate - Double(integer)
    if fraction <= 1/8 {
        return "\(integer)"
    } else if fraction <= 3/8 {
        return "\(integer)¼"
    } else if fraction <= 5/8 {
        return "\(integer)½"
    } else if fraction <= 7/8 {
        return "\(integer)¾"
    } else {
        return "\(integer + 1)"
    }
}

struct Date_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
      let weekday = gregorian.weekdaySymbols[gregorian.component(.weekday, from: entry.date) - 1]
      VStack(alignment: .leading) {
        if let deaths = deaths {
            let interval = Date().timeIntervalSince(marchFirst)
            let rate = (interval / Double(deaths))
            Text("every \(format(rate)) seconds")
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .opacity(0.8)
        }
        HStack { Spacer() }
        Spacer()
        Text(weekday.uppercased())
            .font(.system(.title2, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(.red)
        Text("March")
          .font(.system(.title2, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(.gray)
        Text("\(formatter.string(from: NSNumber(value: gregorian.dateComponents([.day], from: marchFirst, to: entry.date).day!))!)")
          .font(.system(.largeTitle, design: .rounded))
          .bold()
      }.padding()
    }
}

@main
struct Date_Widget: Widget {
    let kind: String = "Date_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Date_WidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Date Widget")
        .description("This widget displays the current date, so you don’t forget!")
    }
}

struct Date_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Date_WidgetEntryView(entry: SimpleEntry(date: midnight(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
