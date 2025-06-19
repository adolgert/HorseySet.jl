"""
Julia implementation of Python's set algorithm for fast, deterministic sets.
Based on CPython's setobject.c implementation.
"""

# Entry states for hash table
@enum EntryState begin
    EMPTY = 0      # Never used
    ACTIVE = 1     # Currently holds a key
    DUMMY = 2      # Previously held a key, now deleted (tombstone)
end

# Hash table entry - equivalent to Python's setentry
mutable struct HashTableEntry{T}
    hash::UInt
    state::EntryState
    key::T
    
    function HashTableEntry{T}() where T
        new{T}(UInt(0), EMPTY)  # Creates struct with all fields uninitialized
    end
    # Constructor for active entry
    HashTableEntry{T}(key::T, hash::UInt) where T = new{T}(hash, ACTIVE, key)
end

# Main hash table structure - equivalent to Python's PySetObject
mutable struct PythonHashSet{T}
    table::Vector{HashTableEntry{T}}
    mask::Int          # table.length - 1 (for fast modulo)
    used::Int          # number of active entries
    fill::Int          # used + number of dummy entries
    
    function PythonHashSet{T}(initial_size::Int = 8) where T
        # Table size must be power of 2
        size = nextpow(2, max(initial_size, 8))
        table = [HashTableEntry{T}() for _ in 1:size]
        new{T}(table, size - 1, 0, 0)
    end
end

# Constants for probing algorithm (from Python's implementation)
const LINEAR_PROBES = 9
const PERTURB_SHIFT = 5

"""
Core lookup function - implements Python's hybrid probing strategy.
Returns the index where the key is found or should be inserted.
"""
function set_lookkey(phs::PythonHashSet{T}, key::T, key_hash::UInt) where T
    table = phs.table
    mask = phs.mask
    
    # Initial probe position
    i = (key_hash & mask) + 1  # Julia uses 1-based indexing
    
    entry = table[i]
    if entry.state == EMPTY || (entry.state == ACTIVE && entry.hash == key_hash && entry.key === key)
        return i
    end
    
    # Linear probing phase
    perturb = key_hash
    for _ in 1:LINEAR_PROBES
        # Python: i = (5*i + 1 + perturb) & mask
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1  # Adjust for 1-based indexing
        entry = table[i]
        
        if entry.state == EMPTY || (entry.state == ACTIVE && entry.hash == key_hash && entry.key === key)
            return i
        end
    end
    
    # Random probing phase with perturbation
    while true
        perturb >>= PERTURB_SHIFT
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1  # Adjust for 1-based indexing
        entry = table[i]
        
        if entry.state == EMPTY || (entry.state == ACTIVE && entry.hash == key_hash && entry.key === key)
            return i
        end
    end
end

"""
Find the first available slot (EMPTY or DUMMY) for insertion.
"""
function set_lookkey_unicode(phs::PythonHashSet{T}, key::T, key_hash::UInt) where T
    table = phs.table
    mask = phs.mask
    
    # Initial probe position
    i = (key_hash & mask) + 1  # Julia uses 1-based indexing
    
    entry = table[i]
    if entry.state != ACTIVE
        return i
    end
    
    if entry.hash == key_hash && entry.key === key
        return i
    end
    
    # Linear probing phase
    perturb = key_hash
    for _ in 1:LINEAR_PROBES
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1
        entry = table[i]
        
        if entry.state != ACTIVE
            return i
        end
        
        if entry.hash == key_hash && entry.key === key
            return i
        end
    end
    
    # Random probing phase
    while true
        perturb >>= PERTURB_SHIFT
        i = ((5 * (i - 1) + 1 + perturb) & mask) + 1
        entry = table[i]
        
        if entry.state != ACTIVE
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
function set_insert_key(phs::PythonHashSet{T}, key::T, key_hash::UInt) where T
    # Find insertion position
    idx = set_lookkey_unicode(phs, key, key_hash)
    entry = phs.table[idx]
    
    if entry.state == ACTIVE
        # Key already exists
        return false
    end
    
    # Insert new key
    if entry.state == EMPTY
        phs.fill += 1
    end
    
    phs.table[idx] = HashTableEntry{T}(key, key_hash)
    phs.used += 1
    
    # Check if resize is needed (load factor > 2/3)
    if phs.fill * 3 >= length(phs.table) * 2
        set_table_resize(phs, phs.used > 50000 ? phs.used * 2 : phs.used * 4)
    end
    
    return true
end

"""
Add a key to the set. Returns true if key was newly added.
"""
function set_add_key(phs::PythonHashSet{T}, key::T) where T
    key_hash = hash(key)
    return set_insert_key(phs, key, key_hash)
end

"""
Check if a key exists in the set.
"""
function set_contains_key(phs::PythonHashSet{T}, key::T) where T
    key_hash = hash(key)
    idx = set_lookkey(phs, key, key_hash)
    return phs.table[idx].state == ACTIVE
end

# Basic interface functions
Base.length(phs::PythonHashSet) = phs.used
Base.isempty(phs::PythonHashSet) = phs.used == 0

"""
Resize the hash table to accommodate more entries.
This is a simplified version of Python's set_table_resize.
"""
function set_table_resize(phs::PythonHashSet{T}, minused::Int) where T
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
    phs.table = [HashTableEntry{T}() for _ in 1:newsize]
    phs.mask = newsize - 1
    phs.used = 0
    phs.fill = 0
    
    # Rehash all active entries
    for entry in oldtable
        if entry.state == ACTIVE
            set_insert_key(phs, entry.key, entry.hash)
        end
    end
    
    return nothing
end

"""
Remove a key from the hash set. Returns true if key was found and removed,
false if key was not found.
"""
function set_discard_key(phs::PythonHashSet{T}, key::T) where T
    key_hash = hash(key)
    idx = set_lookkey(phs, key, key_hash)
    entry = phs.table[idx]
    
    if entry.state != ACTIVE
        # Key not found
        return false
    end
    
    # Mark as dummy (tombstone)
    phs.table[idx] = HashTableEntry{T}()  # Create empty entry
    phs.table[idx].state = DUMMY
    phs.used -= 1
    
    return true
end

"""
Remove a key from the set, throwing an error if not found.
"""
function set_remove_key(phs::PythonHashSet{T}, key::T) where T
    if !set_discard_key(phs, key)
        throw(KeyError(key))
    end
    return nothing
end

"""
Iterator implementation for PythonHashSet.
Returns the next active key and the updated position.
"""
function set_next(phs::PythonHashSet{T}, pos::Int) where T
    table = phs.table
    n = length(table)
    
    # Find next active entry
    while pos <= n
        if table[pos].state == ACTIVE
            return (table[pos].key, pos + 1)
        end
        pos += 1
    end
    
    return nothing
end

# Iterator interface for Julia
function Base.iterate(phs::PythonHashSet{T}) where T
    return set_next(phs, 1)
end

function Base.iterate(phs::PythonHashSet{T}, state::Int) where T
    return set_next(phs, state)
end

# Additional utility functions
function Base.in(key, phs::PythonHashSet)
    return set_contains_key(phs, key)
end

function Base.push!(phs::PythonHashSet{T}, key::T) where T
    set_add_key(phs, key)
    return phs
end

function Base.delete!(phs::PythonHashSet{T}, key::T) where T
    set_remove_key(phs, key)
    return phs
end