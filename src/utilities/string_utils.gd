class_name StringUtils

const ONE_BILLION = pow(10, 9) # 1 Bilhão = 10^9
const ONE_MILLION = pow(10, 6) # 1 Milhão = 10^6
const ONE_THOUSAND = pow(10, 3) # 1 Mil = 10^3


static func format_currency(value: float) -> String:
	if value >= ONE_BILLION:
		var divided = value / ONE_BILLION
		# Se for inteiro, mostra sem decimais, senão mostra com 2 casas
		if int(divided) == divided:
			return str(int(divided)) + "b"
		else:
			return str(snapped(divided, 0.01)) + "b"

	elif value >= ONE_MILLION:
		var divided = value / ONE_MILLION
		if int(divided) == divided:
			return str(int(divided)) + "m"
		else:
			return str(snapped(divided, 0.01)) + "m"

	elif value >= ONE_THOUSAND:
		var divided = value / ONE_THOUSAND
		if int(divided) == divided:
			return str(int(divided)) + "k"
		else:
			return str(snapped(divided, 0.01)) + "k"

	else:
		# Para valores normais, mostra como inteiro se for inteiro
		if int(value) == value:
			return str(int(value))
		else:
			return str(snapped(value, 0.01))

static func format_decimal(value: float, decimal_size: int = 2) -> String:
	return str(snapped(value, pow(0.1, decimal_size)))

static func format_to_percentage(value: float, decimal_size: int = 2) -> String:
	return str(snapped(value * 100, pow(0.1, decimal_size)), "%")

static func format_to_timer(elapsed_game_time: float) -> String:
	var hours := int(elapsed_game_time / 3600)
	var minutes := int(float(int(elapsed_game_time) % 3600) / 60)
	var seconds := int(elapsed_game_time) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

static func format_seconds_to_minutes(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]