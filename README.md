# README

- `rails s` or `PATCH=true rails s`
- `ab -c1 -n100 http://localhost:3000`

## Results

```
Without patch:

Heap slots: 337292/448763
# ... constantly increasing
Heap slots: 347697/448763

With patch:

Heap slots: 337332/441030
# in 5 requests get to
Heap slots: 338240/441030
# and doesn't change much anymore (+/-10)
# Doesn't change at all for small templates.

```

## License

MIT
