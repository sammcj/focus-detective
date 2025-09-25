//
//  FocusDetectiveApp.swift
//  FocusDetective
//
//  Created by Mike Piontek on 9/3/24.
//

import SwiftUI

@main
struct FocusDetectiveApp: App {

	@State var observer = FocusObserver()

	var body: some Scene {

		WindowGroup {

			List {

				Text("The most recent application is shown at the top. You can close this window or hide the application, and Focus Detective will continue to detect changes in the background.")
					.font(.callout)
					.padding(.bottom, 4)

				ForEach(observer.changes) { change in
					HStack(alignment: .firstTextBaseline) {
						Text(change.date.formatted(.dateTime.hour().minute().second(.twoDigits)))
							.font(.callout)
							.monospacedDigit()
							.frame(width: 90, alignment: .leading)
							.accessibilityLabel("Time: \(change.date.formatted(.dateTime.hour().minute().second(.twoDigits)))")
						Text(verbatim: change.name)
							.font(.headline)
							.accessibilityLabel("Application: \(change.name)")
					}
					.padding(.vertical, 4)
					.accessibilityElement(children: .combine)
				}

			}
			.frame(minWidth: 380)
			.navigationTitle("Focus Detective")
			.toolbar {
				Button("Open Console", systemImage: "list.bullet.rectangle") {
					openConsoleApp()
				}
				.accessibilityHint("Opens the Console application to view system logs")
			}

		}
		.defaultSize(width: 380, height: 380)
		.defaultPosition(.center)

	}

	private func openConsoleApp() {
		let workspace = NSWorkspace.shared
		guard let url = workspace.urlForApplication(withBundleIdentifier: "com.apple.Console") else {
			print("Console application not found")
			return
		}

		NSWorkspace.shared.openApplication(at: url, configuration: .init())
	}

}

@Observable
@MainActor
class FocusObserver {

	var changes: [FocusChange] = []

	@ObservationIgnored
	private var observer: NSObjectProtocol?

	init() {
		let center = NSWorkspace.shared.notificationCenter
		observer = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
			object: nil, queue: nil) { [weak self] notification in
			let date = Date.now
			let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
			let name = app?.localizedName ?? "Unknown"
			let change = FocusChange(date: date, name: name)
			Task { @MainActor in
				self?.changes.insert(change, at: 0)
			}
		}
	}

}

struct FocusChange: Identifiable {
	let id = UUID()
	let date: Date
	let name: String
}
