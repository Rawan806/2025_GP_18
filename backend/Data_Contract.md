# Data Contract

## Required Fields

| Field | Type | Description |
|------|------|------------|
| docId | String | Unique ID |
| imageUrl | String | Image link |
| collection | String | "lost" or "found" |

---

## Optional Fields

| Field | Type | Description |
|------|------|------------|
| type | String | Item type |
| color | String | Item color |
| aiTypes | String | AI predicted type |
| aiColor | String | AI predicted color |
| status | String | Item status |
| createdAt | String | Timestamp |

---

## Notes

- docId, imageUrl, collection are required  
- collection must be "lost" or "found"  
- imageUrl must be valid
