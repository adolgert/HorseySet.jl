"""
Julia implementation of Python's set algorithm using IMMUTABLE HashTableEntry.
This version explores the performance implications of immutable vs mutable entries.
"""

# Entry states for hash table
@enum EntryStateImmutable begin
    EMPTY_IMM = 0      # Never used
    ACTIVE_IMM = 1     # Currently holds a key
    DUMMY_IMM = 2      # Previously held a key, now deleted (tombstone)
end

# Immutable hash table entry - equivalent to Python's setentry
struct HashTableEntryImmutable{T}
    hash::UInt
    state::EntryStateImmutable
    key::T
    
    # Constructor for empty entry - leaves key uninitialized
    HashTableEntryImmutable{T}() where T = new{T}(UInt(0), EMPTY_IMM)
    
    # Constructor for active entry
    HashTableEntryImmutable{T}(key::T, hash::UInt) where T = new{T}(hash, ACTIVE_IMM, key)
    
    # Constructor for dummy entry (tombstone)
    HashTableEntryImmutable{T}(::Val{:dummy}) where T = new{T}(UInt(0), DUMMY_IMM)
end

# Main hash table structure - equivalent to Python's PySetObject
mutable struct PythonHashSetImmutable{T}
    table::Vector{HashTableEntryImmutable{T}}
    mask::Int          # table.length - 1 (for fast modulo)
    used::Int          # number of active entries
    fill::Int          # used + number of dummy entries
    
    function PythonHashSetImmutable{T}(initial_size::Int = 8) where T
        # Table size must be power of 2
        size = nextpow(2, max(initial_size, 8))
        table = [HashTableEntryImmutable{T}() for _ in 1:size]
        new{T}(table, size - 1, 0, 0)
    end
end

# Constants for probing algorithm (from Python's implementation)
const LINEAR_PROBES_IMM = 9
const PERTURB_SHIFT_IMM = 5

"""
Core lookup function - implements Python's hybrid probing strategy.
Returns the index where the key is found or should be inserted.
"""
function set_lookkey_imm(phs::PythonHashSetImmutable{T}, key::T, key_hash::UInt) where T
    table = phs.table
    mask = phs.mask
    
    # Initial probe position
    i = (key_hash & mask) + 1  # Julia uses 1-based indexing
    
    entry = table[i]
    if entry.state == EMPTY_IMM || (entry.state == ACTIVE_IMM && entry.hash == key_hash && entry.key === key)
        return i
    end
    
    # Linear probing phase
    perturb = key_hash
    for _ in 1:LINEAR_PROBES_IMM
        # Python: i = (5*i + 1 + perturb) & mask
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1  # Adjust for 1-based indexing
        entry = table[i]
        
        if entry.state == EMPTY_IMM || (entry.state == ACTIVE_IMM && entry.hash == key_hash && entry.key === key)
            return i
        end
    end
    
    # Random probing phase with perturbation
    while true
        perturb >>= PERTURB_SHIFT_IMM
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1  # Adjust for 1-based indexing
        entry = table[i]
        
        if entry.state == EMPTY_IMM || (entry.state == ACTIVE_IMM && entry.hash == key_hash && entry.key === key)
            return i
        end
    end
end

"""
Find the first available slot (EMPTY or DUMMY) for insertion.
"""
function set_lookkey_unicode_imm(phs::PythonHashSetImmutable{T}, key::T, key_hash::UInt) where T
    table = phs.table
    mask = phs.mask
    
    # Initial probe position
    i = (key_hash & mask) + 1  # Julia uses 1-based indexing
    
    entry = table[i]
    if entry.state != ACTIVE_IMM
        return i
    end
    
    if entry.hash == key_hash && entry.key === key
        return i
    end
    
    # Linear probing phase
    perturb = key_hash
    for _ in 1:LINEAR_PROBES_IMM
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1
        entry = table[i]
        
        if entry.state != ACTIVE_IMM
            return i
        end
        
        if entry.hash == key_hash && entry.key === key
            return i
        end
    end
    
    # Random probing phase
    while true
        perturb >>= PERTURB_SHIFT_IMM
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1
        entry = table[i]
        
        if entry.state != ACTIVE_IMM
            return i
        end
        
        if entry.hash == key_hash && entry.key === key
            return i
        end
    end
end

"""
Insert a key into the hash set. Returns true if key was newly inserted,
false if key already existed.
"""
function set_insert_key_imm(phs::PythonHashSetImmutable{T}, key::T, key_hash::UInt) where T
    # Find insertion position
    idx = set_lookkey_unicode_imm(phs, key, key_hash)
    entry = phs.table[idx]
    
    if entry.state == ACTIVE_IMM
        # Key already exists
        return false
    end
    
    # Insert new key - CREATE NEW IMMUTABLE ENTRY
    if entry.state == EMPTY_IMM
        phs.fill += 1
    end
    
    phs.table[idx] = HashTableEntryImmutable{T}(key, key_hash)  # New immutable entry
    phs.used += 1
    
    # Check if resize is needed (load factor > 2/3)
    if phs.fill * 3 >= length(phs.table) * 2
        set_table_resize_imm(phs, phs.used > 50000 ? phs.used * 2 : phs.used * 4)
    end
    
    return true
end

"""
Add a key to the set. Returns true if key was newly added.
"""
function set_add_key_imm(phs::PythonHashSetImmutable{T}, key::T) where T
    key_hash = hash(key)
    return set_insert_key_imm(phs, key, key_hash)
end

"""
Check if a key exists in the set.
"""
function set_contains_key_imm(phs::PythonHashSetImmutable{T}, key::T) where T
    key_hash = hash(key)
    idx = set_lookkey_imm(phs, key, key_hash)
    return phs.table[idx].state == ACTIVE_IMM
end

# Basic interface functions
Base.length(phs::PythonHashSetImmutable) = phs.used
Base.isempty(phs::PythonHashSetImmutable) = phs.used == 0

"""
Resize the hash table to accommodate more entries.
This is a simplified version of Python's set_table_resize.
"""
function set_table_resize_imm(phs::PythonHashSetImmutable{T}, minused::Int) where T
    # Calculate new size (must be power of 2)
    newsize = 8
    while newsize <= minused && newsize < typemax(Int) ÷ 2
        newsize <<= 1
    end
    
    # Don't shrink too much
    if newsize < 8
        newsize = 8
    end
    
    # Save old table
    oldtable = phs.table
    
    # Create new table
    phs.table = [HashTableEntryImmutable{T}() for _ in 1:newsize]
    phs.mask = newsize - 1
    phs.used = 0
    phs.fill = 0
    
    # Rehash all active entries
    for entry in oldtable
        if entry.state == ACTIVE_IMM
            set_insert_key_imm(phs, entry.key, entry.hash)
        end
    end
    
    return nothing
end

"""
Remove a key from the hash set. Returns true if key was found and removed,
false if key was not found.
"""
function set_discard_key_imm(phs::PythonHashSetImmutable{T}, key::T) where T
    key_hash = hash(key)
    idx = set_lookkey_imm(phs, key, key_hash)
    entry = phs.table[idx]
    
    if entry.state != ACTIVE_IMM
        # Key not found
        return false
    end
    
    # Mark as dummy (tombstone) - CREATE NEW IMMUTABLE DUMMY ENTRY
    phs.table[idx] = HashTableEntryImmutable{T}(Val(:dummy))
    phs.used -= 1
    
    return true
end

"""
Remove a key from the set, throwing an error if not found.
"""
function set_remove_key_imm(phs::PythonHashSetImmutable{T}, key::T) where T
    if !set_discard_key_imm(phs, key)
        throw(KeyError(key))
    end
    return nothing
end

"""
Iterator implementation for PythonHashSetImmutable.
Returns the next active key and the updated position.
"""
function set_next_imm(phs::PythonHashSetImmutable{T}, pos::Int) where T
    table = phs.table
    n = length(table)
    
    # Find next active entry
    while pos <= n
        if table[pos].state == ACTIVE_IMM
            return (table[pos].key, pos + 1)
        end
        pos += 1
    end
    
    return nothing
end

# Iterator interface for Julia
function Base.iterate(phs::PythonHashSetImmutable{T}) where T
    return set_next_imm(phs, 1)
end

function Base.iterate(phs::PythonHashSetImmutable{T}, state::Int) where T
    return set_next_imm(phs, state)
end

# Additional utility functions
function Base.in(key, phs::PythonHashSetImmutable)
    return set_contains_key_imm(phs, key)
end

function Base.push!(phs::PythonHashSetImmutable{T}, key::T) where T
    set_add_key_imm(phs, key)
    return phs
end

function Base.delete!(phs::PythonHashSetImmutable{T}, key::T) where T
    set_remove_key_imm(phs, key)
    return phs
end