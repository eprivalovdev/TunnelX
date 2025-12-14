import Foundation

@propertyWrapper
struct XrayStoredCodable<Value: Codable> {
	private let key: String
	private let defaultValue: Value
	private let store: UserDefaults
	
	init(_ key: String, default defaultValue: Value) {
		self.key = key
		self.defaultValue = defaultValue
		self.store = DefaultsSuite.current
	}
	
	var wrappedValue: Value {
		get {
			guard let data = store.data(forKey: key) else { return defaultValue }
			return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
		}
		set {
			let data = try? JSONEncoder().encode(newValue)
			store.set(data, forKey: key)
		}
	}
}

@propertyWrapper
struct XrayStored<Value> {
	private let key: String
	private let defaultValue: Value
	private let store: UserDefaults
	
	init(_ key: String, default defaultValue: Value) {
		self.key = key
		self.defaultValue = defaultValue
		self.store = DefaultsSuite.current
	}
	
	var wrappedValue: Value {
		get {
			if let value = store.object(forKey: key) as? Value {
				return value
			}
			return defaultValue
		}
		set {
			store.set(newValue, forKey: key)
		}
	}
}
