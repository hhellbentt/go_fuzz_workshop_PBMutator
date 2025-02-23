func FuzzParseJSON(t *testing.T) {
	f.Fuzz(func(t *testing.T, orig string) {
		gjson.Parse(orig)
	})
}