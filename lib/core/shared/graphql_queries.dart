// GraphQL Queries and Mutations for Charity App

class GraphQLQueries {
  // Query to list all charities (FIXED: Removed createdAt and updatedAt)
  static const String listCharitiesWithCategories = '''
    query ListCharitiesWithCategories(\$limit: Int, \$nextToken: String) {
      listCharitiesWithCategories(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          name
          mission
          email
          phone
          website
          program
          programDescription
          processLink
          product
          category
        }
        nextToken
      }
    }
  ''';

  // Query to get a specific charity by ID (FIXED: Removed createdAt and updatedAt)
  static const String getCharitiesWithCategories = '''
    query GetCharitiesWithCategories(\$id: ID!) {
      getCharitiesWithCategories(id: \$id) {
        id
        name
        mission
        email
        phone
        website
        program
        programDescription
        processLink
        product
        category
      }
    }
  ''';

  // Query to list all bookmarks
  static const String listBookmarks = '''
    query ListBookmarks(\$limit: Int, \$nextToken: String) {
      listBookmarks(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          userId
          charityName
          charityId
          category
          createdAt
        }
        nextToken
      }
    }
  ''';

  // Mutation to create a bookmark
  static const String createBookmark = '''
    mutation CreateBookmark(\$input: CreateBookmarkInput!) {
      createBookmark(input: \$input) {
        id
        userId
        charityName
        charityId
        category
        createdAt
      }
    }
  ''';

  // Mutation to delete a bookmark
  static const String deleteBookmark = '''
    mutation DeleteBookmark(\$input: DeleteBookmarkInput!) {
      deleteBookmark(input: \$input) {
        id
      }
    }
  ''';
}
