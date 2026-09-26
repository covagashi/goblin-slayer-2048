class_name GameLocale
extends RefCounted
## Native language names stay readable even when the current language is unfamiliar.

const NAMES := {
	&"en": "English",
	&"es": "Español",
	&"pt_BR": "Português (Brasil)",
	&"fr": "Français",
	&"de": "Deutsch",
	&"it": "Italiano",
}


static func from_device(locale: String) -> StringName:
	var base := locale.replace("-", "_").to_lower().get_slice("_", 0)
	# Brazilian Portuguese is the available Portuguese translation.
	if base == "pt":
		return &"pt_BR"
	return StringName(base) if NAMES.has(StringName(base)) else &"en"


static func preference(saved: Variant, device_locale: String) -> StringName:
	if (saved is String or saved is StringName) and NAMES.has(StringName(saved)):
		return StringName(saved)
	return from_device(device_locale)
