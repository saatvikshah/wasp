module Parser.ParserTest where

import Data.Either
import NpmDependency as ND
import Parser
import Parser.Common (runWaspParser)
import qualified Psl.Parser.Model
import qualified StrongPath as SP
import Test.Tasty.Hspec
import Wasp
import qualified Wasp.Auth
import qualified Wasp.Entity
import qualified Wasp.JsImport
import qualified Wasp.NpmDependencies
import qualified Wasp.Page
import qualified Wasp.Query
import qualified Wasp.Route as R

spec_parseWasp :: Spec
spec_parseWasp =
  describe "Parsing wasp" $ do
    it "When given wasp without app, should return Left" $ do
      isLeft (parseWasp "hoho") `shouldBe` True

    before (readFile "test/Parser/valid.wasp") $ do
      it "When given a valid wasp source, should return correct Wasp" $ \wasp ->
        do
          parseWasp wasp
          `shouldBe` Right
            ( fromWaspElems
                [ WaspElementApp $
                    App
                      { appName = "test_app",
                        appTitle = "Hello World!",
                        appHead = Nothing
                      },
                  WaspElementAuth $
                    Wasp.Auth.Auth
                      { Wasp.Auth._userEntity = "User",
                        Wasp.Auth._methods = [Wasp.Auth.EmailAndPassword],
                        Wasp.Auth._onAuthFailedRedirectTo = "/test"
                      },
                  WaspElementRoute $
                    R.Route
                      { R._urlPath = "/",
                        R._targetPage = "Landing"
                      },
                  WaspElementPage $
                    Wasp.Page.Page
                      { Wasp.Page._name = "Landing",
                        Wasp.Page._component =
                          Wasp.JsImport.JsImport
                            { Wasp.JsImport._defaultImport = Just "Landing",
                              Wasp.JsImport._namedImports = [],
                              Wasp.JsImport._from = [SP.relfileP|pages/Landing|]
                            },
                        Wasp.Page._authRequired = Just False
                      },
                  WaspElementRoute $
                    R.Route
                      { R._urlPath = "/test",
                        R._targetPage = "TestPage"
                      },
                  WaspElementPage $
                    Wasp.Page.Page
                      { Wasp.Page._name = "TestPage",
                        Wasp.Page._component =
                          Wasp.JsImport.JsImport
                            { Wasp.JsImport._defaultImport = Just "Test",
                              Wasp.JsImport._namedImports = [],
                              Wasp.JsImport._from = [SP.relfileP|pages/Test|]
                            },
                        Wasp.Page._authRequired = Nothing
                      },
                  WaspElementEntity $
                    Wasp.Entity.Entity
                      { Wasp.Entity._name = "Task",
                        Wasp.Entity._fields =
                          [ Wasp.Entity.Field
                              { Wasp.Entity._fieldName = "id",
                                Wasp.Entity._fieldType = Wasp.Entity.FieldTypeScalar Wasp.Entity.Int
                              },
                            Wasp.Entity.Field
                              { Wasp.Entity._fieldName = "description",
                                Wasp.Entity._fieldType = Wasp.Entity.FieldTypeScalar Wasp.Entity.String
                              },
                            Wasp.Entity.Field
                              { Wasp.Entity._fieldName = "isDone",
                                Wasp.Entity._fieldType = Wasp.Entity.FieldTypeScalar Wasp.Entity.Boolean
                              }
                          ],
                        Wasp.Entity._pslModelBody =
                          fromRight (error "failed to parse") $
                            runWaspParser
                              Psl.Parser.Model.body
                              "\
                              \    id          Int     @id @default(autoincrement())\n\
                              \    description String\n\
                              \    isDone      Boolean @default(false)"
                      },
                  WaspElementQuery $
                    Wasp.Query.Query
                      { Wasp.Query._name = "myQuery",
                        Wasp.Query._jsFunction =
                          Wasp.JsImport.JsImport
                            { Wasp.JsImport._defaultImport = Nothing,
                              Wasp.JsImport._namedImports = ["myJsQuery"],
                              Wasp.JsImport._from = [SP.relfileP|some/path|]
                            },
                        Wasp.Query._entities = Nothing,
                        Wasp.Query._auth = Nothing
                      },
                  WaspElementNpmDependencies $
                    Wasp.NpmDependencies.NpmDependencies
                      { Wasp.NpmDependencies._dependencies =
                          [ ND.NpmDependency
                              { ND._name = "lodash",
                                ND._version = "^4.17.15"
                              }
                          ]
                      }
                ]
                `setJsImports` [JsImport (Just "something") [] [SP.relfileP|some/file|]]
            )
